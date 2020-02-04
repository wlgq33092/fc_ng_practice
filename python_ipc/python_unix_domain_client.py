import os
import sys
import socket
import time
import struct

sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

sock_path = "/home/wuge/.mytmp/unix-domain-socket-test.sock"

sock.connect(sock_path)

send_data = "This is python client"
send_len = len(send_data)
print "send data: len: {0}, data: {1}".format(send_len, send_data)
send_data_struct = struct.pack('>1i%ds' % send_len, send_len, send_data)

sock.sendall(send_data_struct)
data = sock.recv(32)
datalen, data_struct = struct.unpack('>1i%ds' % (len(data) - 4), data)
print "recv data len: {0}, data: {1}\n".format(datalen, data_struct)
