import os
import sys
import socket
import time
import struct
import json
import importlib

from py_msg import FCMessage
from py_rpc import PyLangServer, PyLangClient
import pyserver_context
import context
import log_agent

# import_path = os.path.abspath(__file__)
# fake_jobs_path = import_path + "/../../fake_jobs/python_fake_jobs"

from pyjoba import pyjoba

jobs = {}

def call_job_method(job, method, *args):
    if method not in job.__dict__:
        func = getattr(job, method)
        print "call job method:\n"
        print args
        print "\n"
        ret = func(*args)
        print "return val is " + ret + "\n"
        return ret
    else:
        print "no method!"

def handle_rpc_message(req):
    global jobs
    jobname = req["job_name"]
    jobtype = req["job_type"]
    method = req["method"]
    args = req["args"]

    print req
    print "handle rpc msg: name {0}, type {1}, method {2}".format(jobname, jobtype, method)
    job = jobs[jobname]
    print job.__dict__
    ret = call_job_method(job, method, *args)
    ret_dic = {"return_val":ret}
    ret_msg = FCMessage(context.FC_MSG_RESP, ret_dic)

    return ret_msg
    # getattr(job, method)

def handle_get_attr_message(req):
    global jobs
    job_name = req["job_name"]
    attr = req["attr"]
    print ""


def handle_fc_message(msg):
    tag = msg.get_tag()
    if tag == context.FC_MSG_RPC:
        return handle_rpc_message(msg.get_value())
    elif tag == context.FC_MSG_GET_REMOTE_ATTR:
        return handle_get_attr_message(msg.get_value())
    else:
        print "unknown message.\n"

def init_jobs():
    jobs["job3"] = pyjoba("job3", "pyjoba")
    jobs["job4"] = pyjoba("job4", "pyjoba")

if __name__ == "__main__":
    # import_path = os.path.dirname(os.path.abspath(__file__))
    # print "import path: " + import_path + "\n"
    # sys.path.append(import_path)
    # sys.path.append(context.job_packages_folder)
    # sys.path.append(context.log_service_folder)
    print sys.path
    importlib.import_module("pyjoba")
    importlib.import_module("fc_logging")

    init_jobs()

    server = PyLangServer(context.get_sock_path('python'), 5)
    while True:
        server.accept()
        while True:
            msg = server.recv_req()
            if msg is None:
                break

            ret_msg = handle_fc_message(msg)
            print ret_msg
            server.send_resp(ret_msg)

