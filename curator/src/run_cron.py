#!/usr/bin/python

import os
import time
import elasticsearch
from curator_cmd import CuratorCmd
from crontab import CronTab
from datetime import datetime, timedelta
from util import create_logger

class CuratorCronJob():

    def __init__(self):
        self.logger =   create_logger(__name__)
        curator_cmd =   CuratorCmd()
        self.cmd_list = curator_cmd.build_cmd_list()
        self.defaults = curator_cmd.get_defaults()
        self.hour =     self.defaults.get('runhour', 0)
        self.minute =   self.defaults.get('runminute', 0)
        self.timezone = self.defaults.get('timezone', 'UTC')
        self.job_list = CronTab()
        self.ca =       os.getenv('ES_CA', '/etc/curator/keys/ca')
        self.cert =     os.getenv('ES_CLIENT_CERT', '/etc/curator/keys/cert')
        self.key =      os.getenv('ES_CLIENT_KEY', '/etc/curator/keys/key')
        self.es_host =  os.getenv('ES_HOST', 'logging-es')
        self.es_port =  os.getenv('ES_PORT', '9200')

    def setup_cron(self):
        for cmd in self.cmd_list:
            job = self.job_list.new(command=cmd, comment='Generated job based on settings')
            job.every().day()

    def run(self):
        '''
        Run curator job periodically
        Waits till elasticsearch becomes ready.
        '''
        if self.server_ready():
            self.logger.info('curator running [%d] jobs', len(self.job_list))
            for job in self.job_list:
                self.logger.debug('curator running job [%s]', job)
                output = job.run()
                if output:
                    self.logger.info(output)
                else:
                    self.logger.debug('curator job [%s] was successful', job)
            # test-curator looks for this string to mean the jobs are complete
            self.logger.info('curator run finish')

    def loop(self):
        while True:
            # get time when next run should happen - number of seconds until the next hour and minute
            timenow = datetime.now(self.timezone)
            lastruntime = timenow.replace(hour=self.hour, minute=self.minute, second=0, microsecond=0)
            offset = 0
            if timenow > lastruntime:
                # run it same time tomorrow
                offset = 86400
            untilnextruntime = (lastruntime + timedelta(seconds=offset) - timenow).seconds
            self.logger.debug('curator hour [%d] minute [%d] seconds until next runtime [%d] now [%s]', \
                    self.hour, self.minute, untilnextruntime, str(timenow))
            # sleep until then
            time.sleep(untilnextruntime)
            self.run()

    def server_ready(self):
        until_next_retry = 1
        es = self.get_es_client()
        while True:
            try:
                if es.ping():
                    break
            except elasticsearch.ElasticsearchException as err:
                self.logger.error(err)
            time.sleep(until_next_retry)
            if until_next_retry < 300:
                until_next_retry *= 2
        return True

    def get_es_client(self):
        es = elasticsearch.Elasticsearch(
            [self.es_host + ':' + self.es_port],
            use_ssl=True,
            verify_certs=True,
            ca_certs=self.ca,
            client_cert=self.cert,
            client_key=self.key
        )
        es.transport.max_retries = 0
        es.transport.retry_on_status = ()
        return es

if __name__ == '__main__':
    ccj = CuratorCronJob()
    ccj.setup_cron()
    ccj.run()
    ccj.loop()
