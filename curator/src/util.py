#!/usr/bin/python

import os
import logging
import elasticsearch

def create_logger(name):
    lvl = logging._levelNames.get(os.getenv('CURATOR_SCRIPT_LOG_LEVEL', 'INFO'))
    logging.basicConfig()
    logger = logging.getLogger(name)
    logger.setLevel(lvl)
    return logger

def get_es_client(hostport_list, use_ssl, verify_certs, ca_certs, client_cert, client_key):
    es = elasticsearch.Elasticsearch(
        hostport_list,
        use_ssl=True,
        verify_certs=True,
        ca_certs=ca_certs,
        client_cert=client_cert,
        client_key=client_key
    )
    es_logger = logging.getLogger('elasticsearch')
    es_logger.setLevel(logging.ERROR)
    es.transport.max_retries = 0
    es.transport.retry_on_status = ()
    return es
