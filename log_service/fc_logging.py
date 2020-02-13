import logging
import os
import sys
import time

# default logging level: info
# logging level: CRITICAL 50 ERROR 40 WARNING 30 INFO 20 DEBUG 10 NOTSET 0
class FCLogger(object):
    def __init__(self, level, logfile):
        self.logger = logging.getLogger()
        self.logfile = logfile
        # time.strftime('%Y%m%d%H%M')
        # self.logger.formatTime("%Y-%m-%d %H:%M:%S", time.localtime())
        logging.basicConfig(
            level = logging.INFO, format = '%(asctime)s - %(levelname)s: %(message)s', 
            datefmt = '%Y-%m-%d %H:%M:%S', filename = logfile, filemode = 'w')

    def log_print(self, msg):
        self.logger.info(msg)

    def log_error(self, msg):
        self.logger.error(msg)
        # TODO, update job.xml, job_messages.txt ...

    def log_debug(self, msg):
        self.logger.debug(msg)

    def set_debug(self):
        # set logging level to DEBUG
        self.logger.setLevel(10)
