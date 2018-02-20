#!/usr/bin/python

"""
Tool that produces command line arguments for curator 3.x based on user defined configuration.
"""

import os
import re
import sys
import time

from pytz import timezone, UnknownTimeZoneError
from parser import Parser
from util import create_logger

try:
    from shlex import quote as shellquote
except:
    from pipes import quote as shellquote

class CuratorCmd():

    RAW_REGEX = 'raw_regex'
    PROJ_PREFIX = 'project.'

    # we can't allow 'hours' since our index timestamp format doesn't allow for that level of granularity
    #allowed_units = {'hours': 'hours', 'days': 'days', 'weeks': 'weeks', 'months': 'months'}
    allowed_units = {'days': 'days', 'weeks': 'weeks', 'months': 'months'}

    def __init__(self):
        config_file = os.getenv('CURATOR_CONF_LOCATION', '/etc/curator/settings/config.yaml')
        parser = Parser(config_file)
        self.conf = parser.parse()
        self.projectre = re.compile(r'^[a-z0-9]([-a-z0-9]*[a-z0-9])?$')
        self.projectmaxlen = 63
        self.allowed_operations = {'delete': 'delete'}
        self.allowed_params = {'raw_regex': self.RAW_REGEX}
        self.curator_settings = {'delete': {}}
        self.logger = create_logger(__name__)
        self.curator_log_level = os.getenv('CURATOR_LOG_LEVEL', 'ERROR')
        self.commands = []


    def check_config(self):
        if len(self.conf) == 0:
            self.logger.error('No configuration supplied.')
            sys.exit(1)
        for project in self.conf:
            if project == '.defaults' or project == '.operations':
                continue
            if self.conf[project][self.RAW_REGEX]:
                # project name is a raw regex
                try:
                    re.compile(project)
                except Exception as error:
                    raise ValueError('[{0}] is not a valid regular expression. Message from compiler: {1}'.format(project, error))
            else:
                # check project's name validity
                if len(project) > self.projectmaxlen:
                    raise ValueError('The project name length must be less than or equal to {0} characters. This is too long: [{1}]'.format(self.projectmaxlen, project))
                    sys.exit(1)
                if not self.projectre.match(project):
                    raise ValueError('The project name must match this regex: [{0}] This does not match: [{1}]'.format(self.projectre.pattern, project))
                    sys.exit(1)
            self.logger.info('Adding project [%s]', project)

        # check timezone
        tzstr = self.conf.get('.defaults', {}).get('timezone', os.getenv('CURATOR_RUN_TIMEZONE', 'UTC'))
        if tzstr:
            try:
                self.conf['.defaults']['timezone'] = timezone(tzstr)
            except (AttributeError, UnknownTimeZoneError) as myex:
                raise ValueError('The timezone must be specified as a string in the tzselect(8) or timedatectl(1) "Region/Locality" format e.g. "America/New_York" or "UTC".  [%s] is not a valid timezone string: error [%s]' % (str(tzstr), str(myex)))
                sys.exit(1)
            except: # unexpected error
                raise ValueError('The timezone must be specified as a string in the tzselect(8) or timedatectl(1) "Region/Locality" format e.g. "America/New_York" or "UTC".  Unexpected error [%s] attempting to parse timezone [%s]' % (str(sys.exc_info()[0]), str(tzstr)))
                sys.exit(1)
            self.logger.debug('Using timezone [%s]' % tzstr)

        return self

    def default_index(self):
        """
        Default command is always present. Even if empty configuration is used.
        If no configuration is supplied default indices are deleted every
        $CURATOR_DEFAULT_DAYS days.
        """
        default_command = ''
        if '.defaults' in self.conf and 'delete' in self.conf['.defaults']:
            unit = self.conf['.defaults']['delete']['unit']
            count = self.conf['.defaults']['delete']['count']
            base_default_cmd = '/usr/bin/curator --loglevel ' + self.curator_log_level + ' ' \
                    + self.connection_info() + ' delete indices --timestring %Y.%m.%d'
            default_command = base_default_cmd \
                    + ' --older-than ' + str(count) \
                    + ' --time-unit ' + unit \
                    + ' --exclude ' + shellquote('^' + re.escape('.searchguard.') + '.*$') \
                    + ' --exclude ' + shellquote('^' + re.escape('.kibana') + '.*$')
        return default_command

    def connection_info(self):
        return '--host ' + os.getenv('ES_HOST') + ' --port ' + os.getenv('ES_PORT') \
                + ' --use_ssl --certificate ' + os.getenv('ES_CA') \
                + ' --client-cert ' + os.getenv('ES_CLIENT_CERT') \
                + ' --client-key ' + os.getenv('ES_CLIENT_KEY') \
                + ' --timeout ' + os.getenv('CURATOR_TIMEOUT', 30)

    def build_cmd(self):
        default_command = self.default_index()
        con_info = self.connection_info()
        for project in self.conf:
            if project == '.defaults':
                continue
            for operation in self.conf[project]:
                if operation in self.allowed_operations:
                    unit = self.conf[project][operation]['unit']
                    count = self.conf[project][operation]['count']
                    raw_regex = self.conf[project][self.RAW_REGEX]
                    
                    if not raw_regex:
                        if project.startswith('.') or project.startswith(self.PROJ_PREFIX):
                            default_command = default_command \
                                    + " --exclude " + shellquote('^' + re.escape(project + '.') + '.*$')
                            this_project = '^' + re.escape(project + '.') + '.*$'
                        else:
                            default_command = default_command \
                                    + " --exclude " + shellquote('^' + re.escape(self.PROJ_PREFIX + project + '.') + '.*$')
                            this_project = '^' + re.escape(self.PROJ_PREFIX + project + '.') + '.*$'
                    else:
                        this_project = project
                        default_command = default_command + " --exclude " + "'" + project + "'"
                    self.curator_settings[operation].setdefault(unit, {}).setdefault(count, []).append(this_project)
                    self.logger.debug('Using [%s] [%d] for [%s]', unit, count, this_project)
                else:
                    if operation not in self.allowed_params:
                        self.logger.error('an unsupported or unknown operation ' + operation + ' was provided... Record skipped')
        
        self.commands.append(default_command)
        for operation in self.curator_settings:
            for unit in self.curator_settings[operation]:
                for value in self.curator_settings[operation][unit]:

                    # construct regex to match all projects for this op/time/unit
                    # regex escape any regex special characters in the project name (there shouldn't be, but just in case)
                    # shellquote to protect any shell special chars in the constructed regex
                    tab_cmd = '/usr/bin/curator --loglevel ' + self.curator_log_level + ' ' \
                            + con_info + ' ' + operation + ' indices --timestring %Y.%m.%d' \
                            + ' --older-than ' + str(value) + ' --time-unit ' + unit \
                            + ' --regex ' \
                            + shellquote('(' + '|'.join(map(
                                lambda project: project,
                                self.curator_settings[operation][unit][value])) + ')')
                    self.commands.append(tab_cmd)
                
    def build_cmd_list(self):
        self.check_config()
        self.build_cmd()
        return self.commands

    def get_defaults(self):
        return self.conf.get('.defaults', {})
 