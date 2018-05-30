#!/usr/bin/python

import logging
import elasticsearch

def create_logger(name, lvl):
    lvl_upper = lvl.upper()
    if lvl_upper not in logging._levelNames:
        raise ValueError('Wrong log level %s, must be one of DEBUG, INFO, WARN, WARNING, ERROR, CRITICAL', lvl_upper)
    logging.basicConfig()
    logger = logging.getLogger(name)
    logger.setLevel(lvl_upper)
    return logger
