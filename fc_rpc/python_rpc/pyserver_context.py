import os
import sys
import json
import importlib

class FlowControlContextConfig(object):
    def __init__(self, conf_file):
        with open(conf_file, 'r') as fc_conf:
            content = fc_conf.readlines()
            self.config = json.loads("\n".join(content))
            
    def get_flow_basedir(self):
        return self.config["flow_basedir"]
    
    def replace_flow_basedir(self, path):
        if path.startswith(r'$flow_basedir'):
            flow_basedir = self.get_flow_basedir()
            replaced = path.replace(r"$flow_basedir", flow_basedir)
            return replaced
        return path
    
    def get_flow_message_config(self):
        return self.replace_flow_basedir(self.config["flow_message_config"])
    
    def get_tmp_sock_dir(self):
        return self.replace_flow_basedir(self.config["tmp_sock_dir"])
    
    def get_server_sock_path(self, server):
        return self.replace_flow_basedir(self.config["rpc_server_config"][server.lower()]["sock_path"])
            
    def get_python_fake_job_packages_folder(self):
        return self.replace_flow_basedir(self.config["python_fake_job_packages_folder"])

    def get_log_service_folder(self):
        return self.replace_flow_basedir(self.config["log_service_folder"])
    
    def get_flow_log_file(self):
        return self.replace_flow_basedir(self.config["flow_log_file"])

class PyRPCServerContext(object):
    def __init__(self):
        flow_context_config = os.environ['FLOW_CONTEXT_CONFIG']
        # print "flow context config file: {0}.\n".format(flow_context_config)
        
        context_config = FlowControlContextConfig(flow_context_config)
        self.context_config = context_config
        
        self.basedir = context_config.get_flow_basedir()
        self.job_packages_folder = context_config.get_python_fake_job_packages_folder()
        self.log_service_folder = context_config.get_log_service_folder()
        # print "run init server context!\n"
        self.tmp_sock_dir = context_config.get_tmp_sock_dir()
        self.flow_log_file = context_config.get_flow_log_file()

        sys.path.append(self.job_packages_folder)
        sys.path.append(self.log_service_folder)
        
        # init flow control messages
        fc_message_config = context_config.get_flow_message_config()
        # print fc_message_config
        self.msg_names = {}
        with open(fc_message_config, 'r') as fc_msg:
            # TODO: set attr
            content = fc_msg.readlines()
            config = json.loads("\n".join(content))
            for key in config["FC_MSG_IDS"]:
                value = config["FC_MSG_IDS"][key]
                # print "set attr: key: {0}, value: {1}.\n".format(key, value)
                # self.__setattr__(key, config["FC_MSG_IDS"][key])
                setattr(self, key, int(value))
                self.msg_names[int(value)] = key

    def get_server_sock_path(self, server):
        return self.context_config.get_server_sock_path(server)
            
    def get_base_dir(self):
        return self.basedir
    
    def set_rpc_server_type(self, server_type):
        self.server_type = server_type
    
    def get_message_name(self, tag):
        print "python context: get message name: tag: " + str(tag) + ", name: " + self.msg_names[int(tag)] + "\n"
        return self.msg_names[int(tag)]

sys.modules["context"] = PyRPCServerContext()