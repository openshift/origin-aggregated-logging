#!/usr/bin/python

import os
import sys
import logging

def create_logger(name):
    logger = logging.getLogger(name)
    lvl = logging._levelNames.get(os.getenv('CURATOR_SCRIPT_LOG_LEVEL', 'INFO'), None)
    if not lvl:
        print >> sys.stderr, 'The CURATOR_SCRIPT_LOG_LEVEL must be one of CRITICAL, ERROR, WARNING, INFO or DEBUG'
        return None
    logger.setLevel(lvl)
    lh = logging.StreamHandler()
    lh.setLevel(lvl)
    lh.setFormatter(logging._defaultFormatter)
    logger.addHandler(lh)
    return logger
