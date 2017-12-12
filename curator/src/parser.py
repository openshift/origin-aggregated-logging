#!/usr/bin/python

"""
Parser for Origin Aggregated Logging curator v3 configuration.
.defaults are seeded from the enviroment if not supplied by the user
"""

import os
import sys
import re
import yaml

from util import create_logger

class Parser():

    DELETE = 'delete'
    UNIT = 'unit'
    COUNT = 'count'
    RAW_REGEX = 'raw_regex'
    RUNHOUR = 'runhour'
    RUNMINUTE = 'runminute'
    TIMEZONE = 'timezone'

    def __init__(self, config_file):
        self.config_file = config_file
        self.allowed_units = {'days': 'days', 'weeks': 'weeks', 'months': 'months'}
        self.default_time_unit = 'days'
        self.default_count = int(os.getenv('CURATOR_DEFAULT_DAYS', 31))
        self.runhour = int(os.getenv('CURATOR_RUN_HOUR', 0))
        self.runminute = int(os.getenv('CURATOR_RUN_MINUTE', 0))
        self.timezone = str(os.getenv('CURATOR_RUN_TIMEZONE', 'UTC'))
        self.logger = create_logger(__name__)
        self.internal_config_yaml = {}

    def read_config_file(self):
        with open(self.config_file) as f:
            config_string = f.read()
            self.config_yaml = yaml.load(config_string) or {}
        return self

    def create_internal_representation(self):
        for project in self.config_yaml:
            proj = {}
            delete = {}
            # check for empty project definitions
            if not self.config_yaml.get(project):
                raise Exception('Invalid configuration. [%s] is incomplete.' % project)
            # handle regexes separately
            if project == '.regex':
                self.parse_regex(self.config_yaml['.regex'])
                continue
            unit, count = self.unit_count(self.config_yaml.get(project, {}).get(self.DELETE, {}))
            delete[self.UNIT] = unit
            delete[self.COUNT] = count
            if project == '.defaults':
                keys = self.config_yaml[project].keys()
                proj[self.RUNHOUR] = int(self.config_yaml[project][self.RUNHOUR]) if self.RUNHOUR in keys else self.runhour
                proj[self.RUNMINUTE] = int(self.config_yaml[project][self.RUNMINUTE]) if self.RUNMINUTE in keys else self.runminute
                proj[self.TIMEZONE] = str(self.config_yaml[project][self.TIMEZONE]) if self.TIMEZONE in keys else self.timezone
            proj[self.RAW_REGEX] = False
            proj[self.DELETE] = delete
            self.internal_config_yaml[project] = proj
        if '.defaults' not in self.internal_config_yaml:
            proj = {}
            proj[self.RUNHOUR] = self.runhour
            proj[self.RUNMINUTE] = self.runminute
            proj[self.TIMEZONE] = self.timezone
            proj[self.RAW_REGEX] = False
            proj[self.DELETE] = { self.UNIT: self.default_time_unit, self.COUNT: self.default_count }
            self.internal_config_yaml['.defaults'] = proj
        return self

    def parse_regex(self, regex_list):
        for regex in self.config_yaml['.regex']:
            # check for empty nodes
            if not regex.get(self.DELETE) or not regex.get('pattern'):
                raise Exception('Invalid configuration. [%s] is incomplete.' % regex)
            proj = {self.DELETE: {}}
            unit, count = self.unit_count(regex.get(self.DELETE, {}))
            proj[self.DELETE][self.UNIT] = unit
            proj[self.DELETE][self.COUNT] = count
            proj[self.RAW_REGEX] = True
            self.internal_config_yaml[regex['pattern']] = proj

    def unit_count(self, delete_node):
        if delete_node == None:
            raise ValueError('Invalid configuration. Empty delete statement.')
        unit = self.default_time_unit
        count = self.default_count
        for key in delete_node.keys():
            if key in self.allowed_units:
                unit = key if key != 'weeks' else 'days'
                count = int(delete_node[key]) if key != 'weeks' else int(delete_node[key]) * 7
            else:
                raise ValueError('Invalid configuration. [{0}] is not allowed unit.'.format(key))
        return (unit, count)

    def parse(self):
        return self.read_config_file().create_internal_representation().get()

    def get(self):
        return self.internal_config_yaml
