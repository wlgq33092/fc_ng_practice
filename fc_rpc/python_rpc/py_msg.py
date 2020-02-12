import sys
import os
import struct
import json

'''
message:
TLV
tag(4 bytes, int) + len(4 bytes, int) + value(len bytes, string)
'''
class FCMessage(object):
    # here input argument value is a dic
    def __init__(self, tag, value):
        self._tag = tag
        self._value_dic = value
        self._value = json.dumps(value)
        self._msg_len = len(self._value)

    # set value with a dic
    def set_value(self, value):
        self._value_dic = value

    def add_item(self, key, value):
        self._value_dic[key] = value

    def get_tag(self):
        return self._tag

    def get_value(self):
        return self._value_dic

    def serialization(self):
        self._value = json.dumps(self._value_dic)
        self._msg_len = len(self._value)
        send_data_struct = struct.pack(
            '>2i%ds' % self._msg_len, self._tag, self._msg_len, self._value)
        return send_data_struct

