#!/usr/bin/python

import os
import sys
import logging

def create_logger(name):
    lvl = logging._levelNames.get(os.getenv('CURATOR_SCRIPT_LOG_LEVEL', 'INFO'))
    logging.basicConfig(level=lvl,
        format='%(asctime)s %(levelname)s\t%(message)s')
    return logging.getLogger(name)
