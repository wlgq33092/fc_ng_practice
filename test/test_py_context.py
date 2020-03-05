import unittest

from pyserver_context import PyRPCServerContext, FlowControlContextConfig

class TestFlowControlContextConfig(unittest.TestCase):
    def test_init(self):
        config_file_path = "/home/wuge/workspace/perl_workspace/flow_control_ng/comm/flow_context_config.json"
        context_config = FlowControlContextConfig(config_file_path)
        try:
            self.assertEqual("/home/wuge/workspace/perl_workspace/flow_control_ng", context_config.get_flow_basedir(), "get flow base dir fail!")
            self.assertEqual("/home/wuge/workspace/perl_workspace/flow_control_ng/fc_rpc/fc_msg/flow_controller_msg.json", context_config.get_flow_message_config(), "get flow message config fail!")
            self.assertEqual("/home/wuge/workspace/perl_workspace/flow_control_ng/log_service", context_config.get_log_service_folder(), "get log service folder fail!")
            self.assertEqual("/home/wuge/.mytmp/unix-domain-socket-test-perl.sock", context_config.get_server_sock_path("perl"), "get perl server sock path")
            self.assertEqual("/home/wuge/.mytmp/unix-domain-socket-test-python.sock", context_config.get_server_sock_path("python"), "get python server sock path")
        except Exception as e:
            print "test case not pass: {0}.\n".format(e)
            raise e
        

class TestPyServerContext(unittest.TestCase):
    def test_init(self):
        context = PyRPCServerContext()
        try:
            self.assertEqual(0, context.FC_MSG_REQ, "check FC_MSG_REQ, actual: {0}.".format(context.FC_MSG_REQ))
            self.assertEqual(1, context.FC_MSG_RESP, "check FC_MSG_RESP, actual: {0}.".format(context.FC_MSG_RESP))
            self.assertEqual(2, context.FC_MSG_RPC, "check FC_MSG_RPC, actual: {0}.".format(context.FC_MSG_RPC))
            self.assertEqual(3, context.FC_MSG_CONFIG, "check FC_MSG_CONFIG, actual: {0}.".format(context.FC_MSG_CONFIG))
            self.assertEqual(4, context.FC_MSG_GET_REMOTE_ATTR, "check FC_MSG_GET_REMOTE_ATTR, actual: {0}.".format(context.FC_MSG_GET_REMOTE_ATTR))
            self.assertEqual(5, context.FC_MSG_REMOTE_ATTR_RET, "check FC_MSG_REMOTE_ATTR_RET, actual: {0}.".format(context.FC_MSG_REMOTE_ATTR_RET))
            self.assertEqual(6, context.FC_MSG_SET_REMOTE_ATTR, "check FC_MSG_SET_REMOTE_ATTR, actual: {0}.".format(context.FC_MSG_SET_REMOTE_ATTR))
            self.assertEqual(7, context.FC_MSG_LOG_PRINT, "check FC_MSG_LOG_PRINT, actual: {0}.".format(context.FC_MSG_LOG_PRINT))
            self.assertEqual(8, context.FC_MSG_JOB_CREATE, "check FC_MSG_JOB_CREATE, actual: {0}.".format(context.FC_MSG_JOB_CREATE))
        except Exception as e:
            print "test case not pass: {0}.\n".format(e)
            raise e
    

if __name__ == "__main__":
    unittest.main()