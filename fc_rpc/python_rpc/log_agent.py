import sys
import os
import fc_logging
import FCLogger as logger

class LogAgent(object):
    def __init__(self, logger):
        self.logger = logger
    
    def log_debug(self, msg):
        self.logger.log_debug(msg)
    
    def log_info(self, msg):
        self.logger.log_info(msg)
    
    def log_warning(self, msg):
        self.logger.log_warning(msg)
    
    def log_error(self, msg):
        self.logger.log_error(msg)
        # TODO, update job_message.txt
    
sys.modules["log_agent"] = LogAgent(logger)
