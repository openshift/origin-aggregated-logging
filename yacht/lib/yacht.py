import elasticsearch
import os
import datetime
import time
from esclientfactory import EsClientFactory
from curatoresclientfactory import CuratorEsClientFactory
from esutil import EsUtil
from util import create_logger

class IndexSource():

    def __init__(self):
        self.logger = create_logger(__name__,  os.getenv('YACHT_LOG_LEVEL', 'INFO'))
        self.es = CuratorEsClientFactory.curator_es_client(False, 'ERROR')

    def indices_tomorrow(self):
        all_indices = self.get_indices()
        filtered_indices = self.filter_indices(all_indices)
        indices_tomorrow = self.format_indices(filtered_indices)
        return indices_tomorrow

    def get_indices(self):
        all_indices = self.es.cat.indices('*', h='index,docs.count', format='json')
        self.logger.debug('all indices: %s', all_indices)
        return all_indices

    def filter_indices(self, all_indices):
        non_empty_indices = filter(lambda record: int(record['docs.count']) > 0 \
            and self.index_name_allowed(record['index']), all_indices)
        operateable_indices = map(lambda record: record['index'], non_empty_indices)
        self.logger.debug('operateable_indices indices: %s', operateable_indices)
        return operateable_indices

    def format_indices(self, indices_today):
        tomorrow = datetime.date.today() + datetime.timedelta(days=1)
        indices_tomorrow = []
        for index in indices_today:
            items = index.split('.')
            items[-1] = tomorrow.strftime('%d') # this way we get 'day' as a zero-padded string
            items[-2] = tomorrow.strftime('%m')
            items[-3] = tomorrow.strftime('%Y')
            index_tomorrow = '.'.join(items)
            indices_tomorrow.append(index_tomorrow)
        self.logger.debug('indices_tomorrow indices: %s', indices_tomorrow)
        return indices_tomorrow

    def index_name_allowed(self, index_name):
        if not index_name.startswith('project.'):
            return False
        subs = index_name.split('.')
        parsed_date = datetime.date(int(subs[-3]), int(subs[-2]), int(subs[-1]))
        if parsed_date != datetime.date.today():
            return False
        return True

class IndexCreator():

    def __init__(self):
        self.logger = create_logger(__name__,  os.getenv('YACHT_LOG_LEVEL', 'DEBUG'))
        self.wait_limit = int(os.getenv('MAX_WATING_TIME', '30000'))
        self.retry_period = int(os.getenv('RETRY_PERIOD_SECONDS', '5'))
        self.index_source = IndexSource()
        self.es = CuratorEsClientFactory.curator_es_client(False, 'ERROR')
        self.es_util = EsUtil(self.es)

    def create(self):
        self.es_util.server_running()
        self.server_busy()
        indices_tomorrow = self.index_source.indices_tomorrow()
        for i in range(len(indices_tomorrow)):
            self.logger.info('Creating index %d of %d [%s]', i+1, len(indices_tomorrow), indices_tomorrow[i])
            try:
                self.es.indices.create(indices_tomorrow[i], ignore=400)
            except elasticsearch.ElasticsearchException as err:
                self.logger.error(err)
        # job done, relly on garbage collector to close open connections to es
        # will sleep now...
        # EsClientFactory.es_reset_con()

    def server_busy(self):
        while self.queue() > self.wait_limit:
            self.logger.debug('elasticsearch cluster too busy, waiting...')
            time.sleep(self.retry_period)

    def queue(self):
        current_queue = self.wait_limit + 1
        try:
            current_queue = self.es.cluster.health()['task_max_waiting_in_queue_millis']
        except elasticsearch.ElasticsearchException as err:
            self.logger.error(err)
        return current_queue

class Yacht():

    def __init__(self):
        self.logger = create_logger(__name__,  os.getenv('YACHT_LOG_LEVEL', 'DEBUG'))
        self.ic = IndexCreator()

    def loop(self):
        while True:
            self.run()
            self.sleep()

    def run(self):
        self.ic.create()

    def sleep(self):
        # cover the edge case when operation finishes in less than a second by adding a second to timenow
        timenow = datetime.datetime.now() + datetime.timedelta(seconds=1)
        lastruntime = timenow.replace(minute=0, second=0, microsecond=0)
        offset = 0
        if timenow >= lastruntime:
            offset = 3600
        # here the extra second would be neutralized, so we have to get rid of it
        untilnextruntime = (lastruntime + datetime.timedelta(seconds=offset) - (timenow - datetime.timedelta(seconds=1))).seconds
        self.logger.debug('yacht run finished. [%d] seconds untill next run', untilnextruntime)
        time.sleep(untilnextruntime)

if __name__ == '__main__':
    yacht = Yacht()
    yacht.loop()
