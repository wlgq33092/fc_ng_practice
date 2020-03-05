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
    
    def get_server_sock_path(self, lang):
        return self.replace_flow_basedir(self.config["rpc_server_sock_path"][lang])
            
    def get_python_fake_job_packages_folder(self):
        return self.replace_flow_basedir(self.config["python_fake_job_packages_folder"])

    def get_log_service_folder(self):
        return self.replace_flow_basedir(self.config["log_service_folder"])

class PyRPCServerContext(object):
    def __init__(self):
        flow_context_config = os.environ['FLOW_CONTEXT_CONFIG']
        print "flow context config file: {0}.\n".format(flow_context_config)
        
        context_config = FlowControlContextConfig(flow_context_config)
        
        self.basedir = context_config.get_flow_basedir()
        self.job_packages_folder = context_config.get_python_fake_job_packages_folder()
        self.log_service_folder = context_config.get_log_service_folder()
        print "run init server context!\n"
        self.tmp_sock_dir = context_config.get_tmp_sock_dir()
        self.PYTHON_SERVER_SOCK_PATH = context_config.get_server_sock_path('python')
        self.PERL_SERVER_SOCK_PATH = context_config.get_server_sock_path('perl')

        sys.path.append(self.job_packages_folder)
        sys.path.append(self.log_service_folder)
        
        # init flow control messages
        fc_message_config = context_config.get_flow_message_config()
        print fc_message_config
        with open(fc_message_config, 'r') as fc_msg:
            # TODO: set attr
            content = fc_msg.readlines()
            config = json.loads("\n".join(content))
            for key in config["FC_MSG_IDS"]:
                value = config["FC_MSG_IDS"][key]
                # print "set attr: key: {0}, value: {1}.\n".format(key, value)
                # self.__setattr__(key, config["FC_MSG_IDS"][key])
                setattr(self, key, int(value))

    def get_sock_path(self, lang):
        if lang == "perl":
            return self.PERL_SERVER_SOCK_PATH
        elif lang == "python":
            return self.PYTHON_SERVER_SOCK_PATH
        
    def set_sock_path(self, lang, sock_path):
        if lang == "perl":
            self.PERL_SERVER_SOCK_PATH = sock_path
        elif lang == "python":
            self.PYTHON_SERVER_SOCK_PATH = sock_path
            
    def get_base_dir(self):
        return self.basedir

sys.modules["context"] = PyRPCServerContext()