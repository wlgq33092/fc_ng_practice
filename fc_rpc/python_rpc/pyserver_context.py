import os
import sys
import json
import importlib

class PyRPCServerContext(object):
    def __init__(self):
        self.job_packages_folder = '/home/wuge/workspace/perl_workspace/flow_control_ng/fake_jobs/python_fake_jobs'
        self.log_service_folder = '/home/wuge/workspace/perl_workspace/flow_control_ng/log_service'
        self.fake_job_folder = '/home/wuge/workspace/perl_workspace/flow_control_ng/fake_jobs/python_fake_jobs'
        print "run init server context!\n"
        self.PYTHON_SERVER_SOCK_PATH = "/home/wuge/.mytmp/unix-domain-socket-test-python.sock"
        self.PERL_SERVER_SOCK_PATH = "/home/wuge/.mytmp/unix-domain-socket-test-perl.sock"

        sys.path.append(self.job_packages_folder)
        sys.path.append(self.log_service_folder)
        sys.path.append(self.fake_job_folder)

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

sys.modules["context"] = PyRPCServerContext()