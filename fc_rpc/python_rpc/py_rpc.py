import os
import sys
import socket
import time
import struct
import json
import importlib
from py_msg import FCMessage
# import pyserver_context as context

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
        print "server accept from {0}\n".format(self.addr)

    def recv_req(self):
        if self.conn:
            msg_tag = self.conn.recv(4)
            msg_len = self.conn.recv(4)
            if not msg_tag:
                return None
            print "recv: raw tag {0}, raw len {1}\n".format(msg_tag, msg_len)
            msg_tag, = struct.unpack('>i', msg_tag)
            msg_len, = struct.unpack('>i', msg_len)
            print "recv: tag {0}, len {1}\n".format(msg_tag, msg_len)
            val = self.conn.recv(msg_len)
            val, = struct.unpack('>%ds' % msg_len, val)
            print "recv: tag {0}, len {1}, val: {2}\n".format(
                msg_tag, msg_len, val)
            val_dic = json.loads(val)
            msg = FCMessage(msg_tag, val_dic)
            return msg
        else:
            print "no conn.\n"
            return None

    def send_resp(self, msg):
        if self.conn:
            send_data_struct = msg.serialization()
            self.conn.sendall(send_data_struct)
        else:
            print "no conn.\n"

class PyLangClient(object):
    def __init__(self):
        pass
