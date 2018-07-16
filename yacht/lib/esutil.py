import time
import elasticsearch
from util import create_logger

class EsUtil():

    def __init__(self, es, log_level):
        if es is None:
            raise ValueError('Received empty elasticsearch client')
        self.logger = create_logger(__name__,  log_level)
        self.es = es

    def server_running(self):
        until_next_retry = 1
        failed_retries = 0
        while True:
            try:
                if self.es.ping():
                    break
                else:
                    # ping returns False if returned http code isn't 2xx
                    failed_retries += 1
                    self.logger.error('Connection to elasticsearch failed. Number of failed retries: %d', \
                        failed_retries)
            except elasticsearch.ElasticsearchException as err:
                # ping() also throws TransportError if elasticsearch is not available
                failed_retries += 1
                self.logger.error('Connection to elasticsearch failed. Number of failed retries: %d', \
                    failed_retries)
            time.sleep(until_next_retry)
            if until_next_retry < 300:
                until_next_retry *= 2
        return True
