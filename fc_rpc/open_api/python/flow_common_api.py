import os
import sys

class JobAgent(object):
    def __init__(self):
        pass
    
    def __getattribute__(self, attr):
        return 1
    
    
if __name__ == "__main__":
    ja = JobAgent()
    print ja.test
    