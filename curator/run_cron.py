#!/usr/bin/python

import sys
import yaml
import os
import time
import logging

from crontab import CronTab
from datetime import datetime

logger = logging.getLogger(__name__)
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

filename = os.getenv('CURATOR_CONF_LOCATION', '/etc/curator') + '/settings'

decoded = []
with open(filename, 'r') as stream:
    decoded = yaml.load(stream) or []

connection_info = '--host ' + os.getenv('ES_HOST') + ' --port ' + os.getenv('ES_PORT') + ' --use_ssl --certificate ' + os.getenv('ES_CA') + ' --client-cert ' + os.getenv('ES_CLIENT_CERT') + ' --client-key ' + os.getenv('ES_CLIENT_KEY')

base_default_cmd = '/usr/bin/curator --loglevel ERROR ' + connection_info + ' delete indices --timestring %Y.%m.%d'
default_command = base_default_cmd + ' --older-than ' + os.getenv('DEFAULT_DAYS') + ' --time-unit days' + ' --exclude .searchguard*' + ' --exclude .kibana*'

for project in decoded:
    for operation in decoded[project]:
        if operation in allowed_operations:
            for unit in decoded[project][operation]:
                value = int(decoded[project][operation][unit])

                if unit in allowed_units:
                    default_command = default_command + " --exclude " + project + '.*'

                    if unit.lower() == "days":
                        if value%7 == 0:
                            unit = "weeks"
                            value = value/7

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
    logger.info("logging-curator running [%d] jobs" % len(joblist))
    for job in joblist:
        logger.debug("logging-curator running job [%s]" % job)
        output = job.run()
        if output:
            logger.info(output)
        else:
            logger.debug("logging-curator job [%s] was successful" % job)
    logger.info("logging-curator run finish")

# run jobs now
run_all_jobs(my_cron)

thehour = int(os.environ.get('CURATOR_CRON_HOUR', 0))
theminute = int(os.environ.get('CURATOR_CRON_MINUTE', 0))

while True:
    # get time when next run should happen
    nextruntime = time.mktime(datetime.now().replace(hour=thehour, minute=theminute,
                                                     second=0, microsecond=0).timetuple())+86400
    # sleep until then
    time.sleep(nextruntime - time.time())
    run_all_jobs(my_cron)
