import os
import sys
import json
import importlib

class PyRPCServerContext(object):
    def __init__(self):
        self.basedir = '/home/wuge/workspace/perl_workspace/flow_control_ng'
        self.job_packages_folder = self.basedir + '/fake_jobs/python_fake_jobs'
        self.log_service_folder = self.basedir + '/log_service'
        self.fake_job_folder = self.basedir + '/fake_jobs/python_fake_jobs'
        print "run init server context!\n"
        self.tmp_sock_dir = '/home/wuge/.mytmp'
        self.PYTHON_SERVER_SOCK_PATH = self.tmp_sock_dir + "/unix-domain-socket-test-python.sock"
        self.PERL_SERVER_SOCK_PATH = self.tmp_sock_dir + "/unix-domain-socket-test-perl.sock"

        sys.path.append(self.job_packages_folder)
        sys.path.append(self.log_service_folder)
        sys.path.append(self.fake_job_folder)
        
        self.FC_MSG_REQ = 0
        self.FC_MSG_RESP = 1
        self.FC_MSG_RPC = 2
        self.FC_MSG_CONFIG = 3
        self.FC_MSG_GET_REMOTE_ATTR = 4
        self.FC_MSG_REMOTE_ATTR_RET = 5
        self.FC_MSG_SET_REMOTE_ATTR = 6

    def get_sock_path(self, lang):
        if lang == "perl":
            return self.PERL_SERVER_SOCK_PATH
        elif lang == "python":
            return self.PYTHON_SERVER_SOCK_PATH
        
    def set_sock_path(self, lang, sock_path):
        if lang == "perl":
            self.PERL_SERVER_SOCK_PATH = sock_path
        elif lang == "python":
            self.PYTHON_SERVER_SOCK_PATH = sock_path
            
    def get_base_dir(self):
        return self.basedir

sys.modules["context"] = PyRPCServerContext()