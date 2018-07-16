import elasticsearch
import logging

class EsClientFactory(object):

    _es = None

    @staticmethod
    def es_client_factory(ca, cert, key, es_hostport_list, disable_retries=False, log_level=None):
        if EsClientFactory._es is not None:
            return EsClientFactory._es

        EsClientFactory._es = elasticsearch.Elasticsearch(
            es_hostport_list,
            use_ssl=True,
            verify_certs=True,
            ca_certs=ca,
            client_cert=cert,
            client_key=key
        )

        if disable_retries:
            EsClientFactory._es.transport.max_retries = 0
            EsClientFactory._es.transport.retry_on_status = ()

        if log_level is not None and log_level in logging._levelNames:
            EsClientFactory._log_level(log_level)

        return EsClientFactory._es

    @staticmethod
    def es_reset_con():
        if EsClientFactory._es is None:
            raise ValueError('Elasticsearch client not initialized')
        EsClientFactory._es = None

    @staticmethod
    def _log_level(lvl):
        lvl_upper = lvl.upper()
        if lvl_upper not in logging._levelNames:
            raise ValueError('Wrong log level %s, must be one of DEBUG, INFO, WARN, WARNING, ERROR, CRITICAL', lvl)
        es_logger = logging.getLogger('elasticsearch')
        es_logger.setLevel(lvl_upper)
