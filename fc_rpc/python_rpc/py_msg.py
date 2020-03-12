import sys
import os
import struct
import json

'''
message:
TLV
tag(4 bytes, int) + len(4 bytes, int) + payload(len bytes, string)
'''
class FCMessage(object):
    # here input argument payload is a dic
    def __init__(self, tag, payload):
        self._tag = tag
        self._payload_dic = payload
        self._payload = json.dumps(payload)
        self._msg_len = len(self._payload)

    # set payload with a dic
    def set_payload(self, payload):
        self._payload_dic = payload

    def add_item(self, key, payload):
        self._payload_dic[key] = payload

    def get_tag(self):
        return self._tag

    def get_payload(self):
        return self._payload_dic
    
    def dump(self):
        print >> sys.stderr, "tag: {0}, payload: {1}\n".format(self._tag, self._payload)

    def serialization(self):
        self._payload = json.dumps(self._payload_dic)
        self._msg_len = len(self._payload)
        send_data_struct = struct.pack(
            '>2i%ds' % self._msg_len, self._tag, self._msg_len, self._payload)
        return send_data_struct

