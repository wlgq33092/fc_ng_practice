import sys
import os
# import log_service

class LogAgent(object):
    def __init__(self):
        pass
    
    def log_debug(self, msg):
        pass
    
    def log_info(self, msg):
        pass
    
    def log_warning(self, msg):
        pass
    
    def log_error(self, msg):
        pass
    
sys.modules["log_agent"] = LogAgent()
