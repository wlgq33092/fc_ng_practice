import os
import sys
import socket
import time
import struct
import json
import importlib
from py_msg import FCMessage
from py_rpc import PyLangServer, PyLangClient
import pyserver_context as context
from pyjoba import pyjoba

'''
PY_FC_RPC = 0

sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

sock_path = "/home/wuge/.mytmp/unix-domain-socket-test-python.sock"

sock.connect(sock_path)

send_data_dic = {
    '_package':'FC_RPC',
    '_method':'rpc_print',
    '_args':'raw content'
}
send_msg = FCMessage(PY_FC_RPC, send_data_dic)
send_data_struct = send_msg.serialization()
sock.sendall(send_data_struct)

raw_tag = sock.recv(4)
raw_len = sock.recv(4)
msg_tag, = struct.unpack('>i', raw_tag)
msg_len, = struct.unpack('>i', raw_len)
print "raw msg tag: {0}, raw msg len: {1}\n".format(raw_tag, raw_len)
print "msg tag: {0}, msg len: {1}\n".format(msg_tag, msg_len)
raw_payload = sock.recv(msg_len)
payload, = struct.unpack('>%ds' % msg_len, raw_payload)
res = json.loads(payload)
print "payload:\n%s" % payload
print "res:\n" + str(res)
'''

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
    ret_msg = FCMessage(context.MSG_TYPE_RESP, ret_dic)

    return ret_msg
    # getattr(job, method)


def handle_fc_message(msg):
    tag = msg.get_tag()
    if tag == context.MSG_TYPE_RPC:
        return handle_rpc_message(msg.get_value())
    else:
        print "unknown message.\n"

def init_jobs():
    jobs["job3"] = pyjoba("job3", "pyjoba")
    jobs["job4"] = pyjoba("job4", "pyjoba")

if __name__ == "__main__":
    import_path = os.path.abspath(__file__)
    sys.path.append(import_path)

    init_jobs()

    server = PyLangServer(context.SERVER_SOCK_PATH, 5)
    while True:
        server.accept()
        while True:
            msg = server.recv_req()
            if msg is None:
                break

            ret_msg = handle_fc_message(msg)
            print ret_msg
            server.send_resp(ret_msg)

