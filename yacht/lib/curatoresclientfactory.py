import os
from esclientfactory import EsClientFactory

class CuratorEsClientFactory():

    @staticmethod
    def curator_es_client(disable_retries=False, log_level=None):
        ca =       os.getenv('ES_CA', '/etc/curator/keys/ca')
        cert =     os.getenv('ES_CLIENT_CERT', '/etc/curator/keys/cert')
        key =      os.getenv('ES_CLIENT_KEY', '/etc/curator/keys/key')
        es_host =  os.getenv('ES_HOST', 'logging-es')
        es_port =  os.getenv('ES_PORT', '9200')
        es_hostport_list = [es_host + ':' + es_port]

        return EsClientFactory.es_client_factory(ca, cert, key, es_hostport_list, disable_retries, log_level)
