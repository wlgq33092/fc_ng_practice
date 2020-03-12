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
import FCLogger as logger
from py_msg import FCMessage

# import_path = os.path.abspath(__file__)
# fake_jobs_path = import_path + "/../../fake_jobs/python_fake_jobs"

from pyjoba import pyjoba

jobs = {}

def simple_resp(value):
    ret_dic = {"return_val": str(value)}
    ret_msg = FCMessage(context.FC_MSG_RESP, ret_dic)
    return ret_msg

def handle_log_print_message(payload):
    # when handle log print message, use log service directly
    logginglevel = int(payload["logginglevel"])
    message = payload["message"]
    logger.log_print(message, logginglevel)
    
    return simple_resp("success")
    
def handle_rpc_server_config(payload):
    logginglevel = payload["logginglevel"]
    logger.set_logging_level(logginglevel)
    
    return simple_resp("success")

def handle_fc_message(msg):
    tag = msg.get_tag()
    msg_name = context.get_message_name(int(tag))
    if tag == context.FC_MSG_LOG_PRINT:
        return handle_log_print_message(msg.get_payload())
    elif tag == context.FC_MSG_CONFIG:
        return handle_rpc_server_config(msg.get_payload())
    else:
        logger.log_error("unknown message.\n")

if __name__ == "__main__":
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('--rpc_server_type', dest = 'rpc_server_type', default = 'python', help = 'specify rpc server type, e.g python or logger')
    args = arg_parser.parse_args()
    server = PyLangServer(context.get_server_sock_path(args.rpc_server_type), 5)
    while True:
        server.accept()
        while True:
            msg = server.recv_req()
            if msg is None:
                break

            ret_msg = handle_fc_message(msg)
            logger.log_debug(ret_msg)
            server.send_resp(ret_msg)

