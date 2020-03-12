import os
import sys
import socket
import time
import struct
import json
import importlib
import argparse

import pyserver_context
import context
from py_rpc import PyLangServer, PyLangClient
from log_agent import LogAgent
import PyRPCServerLogger as rpc_logger
import FCLogger as logger
from py_msg import FCMessage

# import_path = os.path.abspath(__file__)
# fake_jobs_path = import_path + "/../../fake_jobs/python_fake_jobs"

from pyjoba import pyjoba

jobs = {}

def call_job_method(job, method, *args):
    if method not in job.__dict__:
        func = getattr(job, method)
        rpc_logger.log_debug("call job method:\n")
        rpc_logger.log_debug(args)
        rpc_logger.log_debug("\n")
        ret = func(*args)
        rpc_logger.log_debug("return val is " + ret + "\n")
        return ret
    else:
        rpc_logger.log_error("no method!")
        
def get_job_attr(job, attr):
    pass

def simple_resp(value):
    ret_dic = {"return_val": str(value)}
    ret_msg = FCMessage(context.FC_MSG_RESP, ret_dic)
    return ret_msg

def handle_rpc_message(payload):
    global jobs
    jobname = payload["job_name"]
    jobtype = payload["job_type"]
    method = payload["method"]
    args = payload["args"]

    job = jobs[jobname]
    rpc_logger.log_debug(job.__dict__);
    ret = call_job_method(job, method, *args)
    
    return simple_resp(ret)
    # getattr(job, method)

def handle_get_attr_message(payload):
    global jobs
    job_name = payload["job_name"]
    attr = payload["attr"]
    msg = "get job {0} attr {1}".format(job_name, attr)
    logger.log_debug(msg)
    job_instance = jobs[job_name]
    attr_value = get_job_attr(job_name, attr)
    attr_ret_msg_val = { "job_name": job_name, "attr": attr_value }
    attr_ret_msg = FCMessage(context.FC_MSG_REMOTE_ATTR_RET, attr_ret_msg_val)
    return attr_ret_msg

def handle_log_print_message(payload):
    # when handle log print message, use log service directly
    logginglevel = int(payload["logginglevel"])
    message = payload["message"]
    logger.log_print(message, logginglevel)
    
    return None
    # return simple_resp("success")
    

def handle_job_create_message(payload):
    name = payload["name"]
    type = payload["type"]
    config = payload["config"]
    logginglevel = payload["logginglevel"]
    
    job_logger = LogAgent(name, logginglevel)
    jobs[name] = pyjoba(name, "pyjoba", config, job_logger)
    
    return simple_resp("success")

def handle_rpc_server_config(payload):
    logginglevel = payload["logginglevel"]
    logger.set_logging_level(logginglevel)
    
    return simple_resp("success")

def handle_fc_message(msg):
    tag = msg.get_tag()
    msg_name = context.get_message_name(int(tag))
    rpc_logger.log_info("handle message {0}, name {1}".format(tag, msg_name))
    if tag == context.FC_MSG_RPC:
        return handle_rpc_message(msg.get_payload())
    elif tag == context.FC_MSG_GET_REMOTE_ATTR:
        return handle_get_attr_message(msg.get_payload())
    elif tag == context.FC_MSG_LOG_PRINT:
        return handle_log_print_message(msg.get_payload())
    elif tag == context.FC_MSG_JOB_CREATE:
        return handle_job_create_message(msg.get_payload())
    elif tag == context.FC_MSG_CONFIG:
        return handle_rpc_server_config(msg.get_payload())
    else:
        rpc_logger.log_error("unknown message.\n")

if __name__ == "__main__":
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('--rpc_server_type', dest = 'rpc_server_type', default = 'python', help = 'specify rpc server type, e.g python or logger')
    args = arg_parser.parse_args()
    
    context.set_rpc_server_type(args.rpc_server_type)
    server = PyLangServer(context.get_server_sock_path(args.rpc_server_type), 5)
    while True:
        server.accept()
        while True:
            msg = server.recv_req()
            if msg is None:
                break

            ret_msg = handle_fc_message(msg)
            if ret_msg is not None:
                server.send_resp(ret_msg)
            else:
                print "No need to response!\n"

