#!/usr/bin/python

import sys
import yaml
import os
import time
import logging

from crontab import CronTab
from datetime import datetime

logger = logging.getLogger()
# log at INFO by default
logger.setLevel(logging.INFO)
lh = logging.StreamHandler()
lh.setLevel(logging.INFO)
lh.setFormatter(logging._defaultFormatter)
logger.addHandler(lh)

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

base_default_cmd = '/usr/bin/curator --loglevel ERROR ' + connection_info + ' delete indices --timestring %Y.%m.%d'
default_command = base_default_cmd + ' --older-than ' + str(default_value) + ' --time-unit ' + default_time_unit + ' --exclude .searchguard* --exclude .kibana* --exclude .apiman_*'

for project in decoded:
    if project == '.defaults':
        continue
    for operation in decoded[project]:
        if operation in allowed_operations:
            for unit in decoded[project][operation]:
                value = int(decoded[project][operation][unit])

                if unit in allowed_units:
                    default_command = default_command + " --exclude " + project + '.*'

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

            base_cmd = '/usr/bin/curator --loglevel ERROR ' + connection_info + ' ' + operation + ' indices --timestring %Y.%m.%d'
            tab_command = base_cmd + ' --older-than ' + str(value) + ' --time-unit ' + unit

            for project in curator_settings[operation][unit][value]:
                tab_command = tab_command + ' --prefix ' + project + '.'

            job = my_cron.new(command=tab_command, comment='Generated job based on settings')
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
    # get time when next run should happen
    nextruntime = time.mktime(datetime.now().replace(hour=thehour, minute=theminute,
                                                     second=0, microsecond=0).timetuple())
    timenow = time.time()
    if nextruntime < timenow:
        # the next runtime is less than now, so run a day from now
        nextruntime = nextruntime + 86400
        # else run later today
    logger.debug("curator hour [%d] minute [%d] nextruntime [%d] now [%d]" % (thehour, theminute, nextruntime, time.time()))
    # sleep until then
    time.sleep(nextruntime - time.time())
    run_all_jobs(my_cron)
