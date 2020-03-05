use strict;
use warnings;
use JSON;
use Data::Dumper;
use FindBin qw/$Bin/;
use Getopt::Long qw(:config no_ignore_case);
use Test::More;

use lib "$Bin";
use lib "$Bin/../comm";
use common;
# require "common.pm";
require "test_util.pm";

sub exit_test {
    TestUtil::exit_test($_[0]);
}

sub main {
    my @opt_list = ("l=s");
    my %opts = TestUtil::get_test_opt(@opt_list);

    my $basedir = "/home/wuge/workspace/perl_workspace/flow_control_ng/";
    FlowContext::init_context($basedir);

    is(FlowContext::get_server_sock_path("perl"), "/home/wuge/.mytmp/unix-domain-socket-test-perl.sock", "test perl server sock path") or &exit_test;
    is(FlowContext::get_server_sock_path("python"), "/home/wuge/.mytmp/unix-domain-socket-test-python.sock", "test python server sock path") or &exit_test;
    is(FlowContext::get_server_sock_path("go"), undef, "test go server path") or &exit_test;
    
    # test msg ids init
    {
        # To avoid warnings
        no warnings "once";
        is(0, $FlowContext::FC_MSG_REQ, "test msg id: FC_MSG_REQ");
        # ok(0 == $FlowContext::FC_MSG_REQ, "test msg id: FC_MSG_REQ");
        is(1, $FlowContext::FC_MSG_RESP, "test msg id: FC_MSG_RESP");
        is(2, $FlowContext::FC_MSG_RPC, "test msg id: FC_MSG_RPC");
        is(3, $FlowContext::FC_MSG_CONFIG, "test msg id: FC_MSG_CONFIG");
        is(4, $FlowContext::FC_MSG_GET_REMOTE_ATTR, "test msg id: FC_MSG_GET_REMOTE_ATTR");
        is(5, $FlowContext::FC_MSG_REMOTE_ATTR_RET, "test msg id: FC_MSG_REMOTE_ATTR_RET");
        is(6, $FlowContext::FC_MSG_SET_REMOTE_ATTR, "test msg id: FC_MSG_SET_REMOTE_ATTR");
        is(7, $FlowContext::FC_MSG_LOG_PRINT, "test msg id: FC_MSG_LOG_PRINT");
        is(8, $FlowContext::FC_MSG_JOB_CREATE, "test msg id: FC_MSG_JOB_CREATE");
    }

    &done_testing;
}

&main;