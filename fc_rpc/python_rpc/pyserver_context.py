import os
import sys


MSG_TYPE_REQ = 0
MSG_TYPE_RESP = 1
MSG_TYPE_RPC = 2

job_packages_folder = '/home/wuge/workspace/perl_workspace/flow_control_ng/fake_jobs/python_fake_jobs'
print "run server context!\n"
sys.path.append(job_packages_folder)

SERVER_SOCK_PATH = "/home/wuge/.mytmp/unix-domain-socket-test-python.sock"
PERL_SERVER_SOCK_PATH = "/home/wuge/.mytmp/unix-domain-socket-test-perl.sock"
