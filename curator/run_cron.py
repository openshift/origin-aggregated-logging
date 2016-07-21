#!/usr/bin/python

import sys
import yaml
import os
import time
import logging

from crontab import CronTab
from datetime import datetime, timedelta
from pytz import timezone, UnknownTimeZoneError
try:
    from shlex import quote as shellquote
except:
    from pipes import quote as shellquote
import re

# metadata.name: Invalid value: "F00": must be a DNS label (at most 63
# characters, matching regex [a-z0-9]([-a-z0-9]*[a-z0-9])?): e.g. "my-name"
projectre = re.compile(r'^[a-z0-9]([-a-z0-9]*[a-z0-9])?$')
projectmaxlen = 63

logger = logging.getLogger()
# log at INFO by default
lvl = logging._levelNames.get(os.getenv('CURATOR_SCRIPT_LOG_LEVEL', 'INFO'), None)
if not lvl:
    logger.error('The CURATOR_SCRIPT_LOG_LEVEL must be one of CRITICAL, ERROR, WARNING, INFO or DEBUG')
    sys.exit(1)

logger.setLevel(lvl)
lh = logging.StreamHandler()
lh.setLevel(lvl)
lh.setFormatter(logging._defaultFormatter)
logger.addHandler(lh)

curlvl = os.getenv('CURATOR_LOG_LEVEL', 'ERROR')
if not curlvl in logging._levelNames:
    logger.error('The CURATOR_LOG_LEVEL must be one of CRITICAL, ERROR, WARNING, INFO or DEBUG')
    sys.exit(1)

# we can't allow 'hours' since our index timestamp format doesn't allow for that level of granularity
#allowed_units = {'hours': 'hours', 'days': 'days', 'weeks': 'weeks', 'months': 'months'}
allowed_units = {'days': 'days', 'weeks': 'weeks', 'months': 'months'}

# allowed operations, currently we'll just allow delete
allowed_operations = {'delete': 'delete'}
curator_settings = {'delete': {}}

filename = os.getenv('CURATOR_CONF_LOCATION', '/etc/curator/settings/config.yaml')

decoded = {}
with open(filename, 'r') as stream:
    decoded = yaml.load(stream) or {}
for project in decoded:
    if project == '.defaults' or project == '.operations':
        continue
    if len(project) > projectmaxlen:
        logger.error('The project name length must be less than or equal to %d characters.  This is too long: [%s]' % (projectmaxlen, project))
        sys.exit(1)
    if not projectre.match(project):
        logger.error('The project name must match this regex: [%s] This does not match: [%s]' % (projectre.pattern, project))
        sys.exit(1)

tzstr = decoded.get('.defaults', {}).get('timezone', os.getenv('CURATOR_RUN_TIMEZONE', 'UTC'))
tz = None
if tzstr:
    try:
        tz = timezone(tzstr)
    except (AttributeError, UnknownTimeZoneError) as myex:
        logger.error('The timezone must be specified as a string in the tzselect(8) or timedatectl(1) "Region/Locality" format e.g. "America/New_York" or "UTC".  [%s] is not a valid timezone string: error [%s]' % (str(tzstr), str(myex)))
        sys.exit(1)
    except: # unexpected error
        logger.error('The timezone must be specified as a string in the tzselect(8) or timedatectl(1) "Region/Locality" format e.g. "America/New_York" or "UTC".  Unexpected error [%s] attempting to parse timezone [%s]' % (str(sys.exc_info()[0]), str(tzstr)))
        sys.exit(1)

connection_info = '--host ' + os.getenv('ES_HOST') + ' --port ' + os.getenv('ES_PORT') + ' --use_ssl --certificate ' + os.getenv('ES_CA') + ' --client-cert ' + os.getenv('ES_CLIENT_CERT') + ' --client-key ' + os.getenv('ES_CLIENT_KEY')

defaults = {'delete': {'days': int(os.getenv('CURATOR_DEFAULT_DAYS', 30))}}
deldefaults = defaults['delete']

default_time_unit = decoded.get('.defaults', defaults).get('delete', deldefaults).keys()[0]
if not default_time_unit in allowed_units:
    logger.error('an unknown time unit of ' + default_time_unit + ' was provided... using days')
    default_time_unit = 'days'

default_value = int(decoded.get('.defaults', defaults).get('delete', deldefaults)[default_time_unit])
if default_time_unit.lower() == "weeks":
    # because our timestring is %Y.%m.%d and does not contain weeks,
    # curator doesn't like asking for trimming in weeks, so convert
    # weeks to days
    default_time_unit = "days"
    default_value = default_value * 7

base_default_cmd = '/usr/bin/curator --loglevel ' + curlvl + ' ' + connection_info + ' delete indices --timestring %Y.%m.%d'
default_command = base_default_cmd + ' --older-than ' + str(default_value) + ' --time-unit ' + default_time_unit + ' --exclude .searchguard* --exclude .kibana*'

for project in decoded:
    if project == '.defaults':
        continue
    for operation in decoded[project]:
        if operation in allowed_operations:
            for unit in decoded[project][operation]:
                value = int(decoded[project][operation][unit])

                if unit in allowed_units:
                    default_command = default_command + " --exclude " + shellquote(re.escape(project + '.') + '*')

                    if unit.lower() == "weeks":
                        unit = "days"
                        value = value * 7

                    curator_settings[operation].setdefault(unit, {}).setdefault(value, []).append(project)
                else:
                    if unit.lower() == "hours":
                        logger.error('time unit "hours" is currently not supported due to our current index level granularity is in days')
                    else:
                        logger.error('an unknown time unit of ' + unit + ' was provided... Record skipped')
        else:
            logger.error('an unsupported or unknown operation ' + operation + ' was provided... Record skipped')

my_cron  = CronTab()
default_job = my_cron.new(command=default_command, comment='Default generated job for curator')
default_job.every().day()

for operation in curator_settings:
    for unit in curator_settings[operation]:
        for value in curator_settings[operation][unit]:

            # construct regex to match all projects for this op/time/unit
            # regex escape any regex special characters in the project name (there shouldn't be, but just in case)
            # shellquote to protect any shell special chars in the constructed regex
            tab_cmd = '/usr/bin/curator --loglevel ' + curlvl + ' ' + connection_info + ' ' + operation + ' indices --timestring %Y.%m.%d' + \
            ' --older-than ' + str(value) + ' --time-unit ' + unit + \
            ' --regex ' + \
            shellquote('(' + '|'.join(map(
                lambda project:'^' + re.escape(project + '.'),
                curator_settings[operation][unit][value])) + ')')
            job = my_cron.new(command=tab_cmd, comment='Generated job based on settings')
            job.every().day()

def run_all_jobs(joblist):
    logger.info("curator running [%d] jobs" % len(joblist))
    for job in joblist:
        logger.debug("curator running job [%s]" % job)
        output = job.run()
        if output:
            logger.info(output)
        else:
            logger.debug("curator job [%s] was successful" % job)
    # test-curator looks for this string to mean the jobs are complete
    logger.info("curator run finish")

# run jobs now
run_all_jobs(my_cron)

thehour = decoded.get('.defaults', {}).get('runhour', None)
if not thehour:
    thehour = os.getenv('CURATOR_RUN_HOUR', None)
if not thehour:
    thehour = defaults.get('runhour', 0)

theminute = decoded.get('.defaults', {}).get('runminute', None)
if not theminute:
    theminute = os.getenv('CURATOR_RUN_MINUTE', None)
if not theminute:
    theminute = defaults.get('runminute', 0)

thehour = int(thehour)
theminute = int(theminute)
while True:
    # get time when next run should happen - number of seconds until the next thehour and theminute
    timenow = datetime.now(tz)
    lastruntime = timenow.replace(hour=thehour, minute=theminute, second=0, microsecond=0)
    offset = 0
    if timenow > lastruntime:
        # run it same time tomorrow
        offset = 86400
    untilnextruntime = (lastruntime + timedelta(seconds=offset) - timenow).seconds
    logger.debug("curator hour [%d] minute [%d] seconds until next runtime [%d] now [%s]" % (thehour, theminute, untilnextruntime, str(timenow)))
    # sleep until then
    time.sleep(untilnextruntime)
    run_all_jobs(my_cron)
