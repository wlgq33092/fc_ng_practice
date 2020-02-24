import os
import sys

class pyjoba(object):
    def __init__(self, name, type):
        self._name = name
        self._type = type

    def test_rpc(self, arg1, arg2):
        return "test python rpc ret"

    def test_run(self, arg1, arg2):
        return "test python run ret"

    def test_call_from_perl(self, arg1, arg2, arg3):
        return "test call from perl"

    def test_call_perl(self, arg1, arg2, arg3):
        pass
    
