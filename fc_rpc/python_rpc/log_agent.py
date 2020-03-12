import sys
import os
import fc_logging
import FCLogger as logger

'''
logging level:
DEV 10
INFO 20
WARNING 30
ERROR 40
'''

# log agent is used in job package and rpc server
class LogAgent(object):
    def __init__(self, name, level):
        self.name = name
        self.level = level
        self.logger = logger
        self.logginglevel = {
            "DEV": 10,
            "INFO": 20,
            "WARNING": 30,
            "ERROR": 40
        }
        self.logginglevel_prefix = {
            self.logginglevel["DEV"]: "DEV", 
            self.logginglevel["INFO"]: "INFO", 
            self.logginglevel["WARNING"]: "WARNING",
            self.logginglevel["ERROR"]: "ERROR"
        }
        
    def _can_print(self, level):
        if self.level > level:
            return False
        else:
            return True
        
    def set_logging_level(self, level):
        self.level = level
    
    def log_debug(self, msg):
        if not self._can_print(self.logginglevel["DEV"]):
            return 
        self._log_print(msg, self.logginglevel["DEV"])
    
    def log_info(self, msg):
        if not self._can_print(self.logginglevel["INFO"]):
            return 
        self._log_print(msg, self.logginglevel["INFO"])
    
    def log_warning(self, msg):
        if not self._can_print(self.logginglevel["WARNING"]):
            return 
        self._log_print(msg, self.logginglevel["WARNING"])
    
    def log_error(self, msg):
        if not self._can_print(self.logginglevel["ERROR"]):
            return 
        self._log_print(msg, self.logginglevel["ERROR"])
        # TODO, update job_message.txt
        
    def _log_print(self, msg, level):
        logginglevel_prefix = self.logginglevel_prefix[level]
        new_msg = "[{0}][{1}]: {2}".format(logginglevel_prefix, self.name, msg)
        self.logger.log_print(new_msg, level)
    
sys.modules["PyRPCServerLogger"] = LogAgent("FLOW - Python Server", 20)
