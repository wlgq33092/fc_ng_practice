import logging
import os
import sys
import time
import pyserver_context
import context

# default logging level: info
# logging level: CRITICAL 50 ERROR 40 WARNING 30 INFO 20 DEBUG 10 NOTSET 0
class FCLogger(object):
    def __init__(self, level, logfile):
        self.logger = logging.getLogger()
        self.logfile = logfile
        # time.strftime('%Y%m%d%H%M')
        # self.logger.formatTime("%Y-%m-%d %H:%M:%S", time.localtime())
        logging.basicConfig(
            level = logging.INFO, format = '%(asctime)s: %(message)s', 
            datefmt = '%Y-%m-%d %H:%M:%S', filename = logfile, filemode = 'w')

    def log_print(self, msg, level):
        if 10 == level:
            self.logger.debug(msg)
        elif 20 == level:
            self.logger.info(msg)
        elif 30 == level:
            self.logger.warning(msg)
        elif level >= 40:
            self.logger.error(msg)
        else:
            self.logger.debug(msg)
            
    def log_info(self, msg):
        self.logger.info(msg)

    def log_error(self, msg):
        self.logger.error(msg)
        # TODO, update job.xml, job_messages.txt ...

    def log_debug(self, msg):
        self.logger.debug(msg)
        
    def log_warning(self, msg):
        self.logger.warning(msg)

    def set_debug(self):
        # set logging level to DEBUG
        self.logger.setLevel(10)
        
    def set_logging_level(self, level):
        self.logger.setLevel(level)

sys.modules["FCLogger"] = FCLogger(10, context.flow_log_file)
