#!/usr/bin/python
# Convert curator config file format used in Origin Aggregated Logging
# to the actions file format used by Curator 5
#
# Point this script to Origin Aggregated Logging config file
# by setting CURATOR_CONF_LOCATION.
#
# Optionally you might use the actions file directly via
# CURATOR_ACTIONS_FILE.
#

import re
import sys
import os
import time
import logging

from ruamel import yaml
from ruamel.yaml.scalarstring import SingleQuotedScalarString

from parser import Parser
from util import create_logger

class LegacyConfigConverter():

    LEGACY_CONFIG = 'CURATOR_CONF_LOCATION'
    ACTIONS_FILE  = 'CURATOR_ACTIONS_FILE'
    PROJ_PREFIX   = 'project.'
    RAW_REGEX     = 'raw_regex'
    ACTIONS_FILE_WRITE_LOCATION = os.getenv('HOME', '/opt/app-root/src') + '/actions.yaml'

    def __init__(self):
        self.logger = create_logger(__name__)
        self.actions_file = os.getenv(self.ACTIONS_FILE, self.ACTIONS_FILE_WRITE_LOCATION)
        self.conf_file = os.getenv(self.LEGACY_CONFIG, None)
        self.projectre = re.compile(r'^[a-z0-9]([-a-z0-9]*[a-z0-9])?$')
        self.projectmaxlen = 63

    def convert(self):
        '''
        Converts legacy configuration to curator 5 actions file
        returns:
          0 - actions file exist, legacy configuration file doesn't exit, no conversion needed
          1 - legacy configuration was converted
          2 - an error occured
        '''
        # legacy config file exists
        if self.conf_file and os.path.isfile(self.conf_file):
            self.logger.info('Found curator configuration in [{0}]'.format(self.conf_file))
            # if both, legacy config file and actions file exist AND actions file is not empty,
            # do not override the actions file
            if os.path.isfile(self.actions_file) and not self.is_empty_actions_file():
                self.logger.info('Found existing actions file [%s]. Skipping legacy config conversion.', self.actions_file)
                return 0
            else:
                # convert legacy config to actions file
                self.logger.info('Converting config file.')
                try:
                    internal_config = self.validate_internal_config(Parser(self.conf_file).parse())
                except ValueError as err:
                    self.logger.error(err)
                    return 2

                self.actions_file = self.ACTIONS_FILE_WRITE_LOCATION
                self.generate(Parser(self.conf_file).parse())
                return 1
        else:
            self.logger.info('Config file not found. Skipping conversion.')
            # generate default action file, if it does not exist or is empty
            if not os.path.isfile(self.actions_file) or (os.path.isfile(self.actions_file) and self.is_empty_actions_file()):
                self.logger.info('Found empty actions file. Generating default actions.')
                self.actions_file = self.ACTIONS_FILE_WRITE_LOCATION
                open(self.actions_file, 'a').close()
                internal_config = Parser(self.actions_file).parse()
                self.generate(internal_config)
                return 1
        return 0

    def generate(self, legacy_config):
        action_id = 1
        actions = { 'actions': {} }
        for project in legacy_config:
            if project == '.defaults' or project == '.regex':
                continue
            unit = legacy_config[project]['delete']['unit']
            count = legacy_config[project]['delete']['count']
            raw_regex = legacy_config[project][self.RAW_REGEX]
            if raw_regex:
                regex = project
            else:
                regex = self.format_regex(project)
            action = self.generate_action(unit, count, regex, exclude=False)
            actions['actions'][action_id] = action
            action_id += 1
        actions['actions'][action_id] = self.generate_defaults(legacy_config)
        with open(self.actions_file, 'w') as f:
            yaml.round_trip_dump(actions, f, default_flow_style=False, explicit_start=True)

    def generate_action(self, unit, count, regex, exclude=False):
        action = {
            'action': 'delete_indices',
            'description': 'auto-generated',
            'options': {
                'ignore_empty_list': True,
                'continue_if_exception': False,
                'timeout_override': os.getenv('CURATOR_TIMEOUT', 300)
            },
            'filters': [
                {
                    'filtertype': 'pattern',
                    'kind': 'regex',
                    'value': SingleQuotedScalarString(regex),
                    'exclude': exclude
                },
                {
                    'filtertype': 'age',
                    'source': 'name',
                    'direction': 'older',
                    'timestring': '%Y.%m.%d',
                    'unit': unit,
                    'unit_count': count
                }
            ]
        }
        return action

    def generate_defaults(self, legacy_config):
        defaults_node = legacy_config['.defaults']
        unit = defaults_node['delete']['unit']
        count = defaults_node['delete']['count']
        projects = legacy_config.keys()
        projects.remove('.defaults')
        if '.regex' in projects:
            projects.remove('.regex')
        regex = '|'.join(
            map(lambda project: project if legacy_config[project][self.RAW_REGEX] else self.format_regex(project), projects)
            +
            map(lambda project: self.format_regex(project), ['.searchguard', '.kibana']))
        return self.generate_action(unit, count, regex, exclude=True)

    def validate_internal_config(self, config):
        for project in config:
            if config[project][self.RAW_REGEX]:
                # project name is a raw regex
                try:
                    re.compile(project)
                except Exception as error:
                    raise ValueError('[{0}] is not a valid regular expression. Message from compiler: {1}'.format(project, error))
            else:
                if project == '.kibana' or project == '.operations' or project == '.defaults' or project == '.searchguard':
                    continue
                # check project's name validity
                if len(project) > self.projectmaxlen:
                    raise ValueError('The project name length must be less than or equal to {0} characters. This is too long: [{1}]'.format(self.projectmaxlen, project))
                if not self.projectre.match(project):
                    raise ValueError('The project name must match this regex: [{0}] This does not match: [{1}]'.format(self.projectre.pattern, project))

    def is_empty_actions_file(self):
        actions_yaml = None
        with open(self.actions_file, 'r') as f:
            actions_string = f.read()
            actions_yaml = yaml.load(actions_string, Loader=yaml.Loader)
        if actions_yaml is None or 'actions' not in actions_yaml:
            return True
        else:
            return False

    def format_regex(self, project):
        if project == '.kibana':
            return '^{0}.*$'.format(re.escape(project))
        elif project.startswith('.') or project.startswith(self.PROJ_PREFIX):
            return '^{0}.*$'.format(re.escape(project + '.'))
        else:
            return '^{0}.*$'.format(re.escape(self.PROJ_PREFIX + project + '.'))

if __name__ == '__main__':
    converter = LegacyConfigConverter()
    result_code = converter.convert()
    sys.exit(result_code)
