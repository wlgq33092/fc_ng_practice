import os
import sys
import socket
import time
import struct
import json
import importlib
from py_msg import FCMessage
import log_agent
import PyRPCServerLogger as rpc_logger
import context

# import pyserver_context as context
def send_fc_message(sock, msg):
    if sock:
        print "send fc message:\n"
        msg.dump()
        send_data_struct = msg.serialization()
        sock.sendall(send_data_struct)
    else:
        rpc_logger.log_error("no conn.\n")

def recv_fc_message(conn):
    if conn:
        msg_tag = conn.recv(4)
        msg_len = conn.recv(4)
        if not msg_tag:
            return None
        # print "recv: raw tag {0}, msg name {1} raw len {2}\n".format(msg_tag, context.get_message_name(msg_tag), msg_len)
        msg_tag, = struct.unpack('>i', msg_tag)
        msg_len, = struct.unpack('>i', msg_len)
        rpc_logger.log_debug("recv: tag {0}, len {1}\n".format(msg_tag, msg_len))
        val = conn.recv(msg_len)
        val, = struct.unpack('>%ds' % msg_len, val)
        rpc_logger.log_debug("recv: tag {0}, len {1}, val: {2}\n".format(
            msg_tag, msg_len, val))
        val_dic = json.loads(val)
        msg = FCMessage(msg_tag, val_dic)
        return msg
    else:
        rpc_logger.log_error("no conn.\n")
        return None

def get_client(server):
    sock_path = context.get_server_sock_path(server.lower())
    if sock_path is None:
        return None
    
    client = PyLangClient(sock_path)
    if client is None:
        return None
    
    return client

class PyLangServer(object):
    def __init__(self, sock_path, max_listen):
        self.sock_path = sock_path
        if os.path.exists(sock_path):
            os.unlink(sock_path)
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.bind(self.sock_path)
        self.sock.listen(max_listen)

    def accept(self):
        self.conn, self.addr = self.sock.accept()
        # print "server accept from {0}\n".format(self.addr)

    def recv_req(self):
        return recv_fc_message(self.conn)

    def send_resp(self, msg):
        send_fc_message(self.conn, msg)

class PyLangClient(object):
    def __init__(self, sock_path):
        self.sock_path = sock_path
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        if sock < 0:
            print >> sys.stderr, "Create client error!\n"
            return None

    def _send_fc_message(self, msg):
        send_fc_message(self.sock, msg)
    
    def _recv_response(self):
        return recv_fc_message()
    
    def _rpc(self, tag, call_data):
        msg = FCMessage(tag, call_data)
        try:
            self._send_fc_message(msg)
            recv_msg = self._recv_response()
            self.sock.close()
            return recv_msg
        except Exception as e:
            print >> sys.stderr, "Python RPC Client do rpc error!\n"
            
    def rpc_log(self, logginglevel, msg):
        call_data = { "logginglevel": logginglevel, "message": msg}
        self._rpc(context.FC_MSG_LOG_PRINT, call_data)