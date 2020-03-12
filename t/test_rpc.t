use strict;
use warnings;
use JSON;
use Data::Dumper;
use FindBin qw/$Bin/;
use Getopt::Long qw(:config no_ignore_case);
use Test::More;

unshift @INC, "$Bin";
unshift @INC, "$Bin/../comm";
require "common.pm";
require "test_util.pm";

sub exit_test {
    TestUtil::exit_test($_[0]);
}

sub main {
    my @opt_list = qw(l=s debug=s);
    my %opts = TestUtil::get_test_opt(@opt_list);

    FlowContext::init_context("$Bin/../");
    FlowContext::set_flow_logger(LogAgent->new("FLOW - Engine", 10));

    require "rpc_obj.pm";

    RegisterCenter::register_job_package("joba", "perl");
    RegisterCenter::register_job_package("pyjoba", "python");

    my $debug = undef;
    if (exists $opts{debug}) {
        if (lc($opts{debug}) eq 'perl' or lc($opts{debug}) eq 'python') {
            $debug = $opts{debug};
        }
    }

    # test rpc server config
    # my $perl_server_config = {

    # };

    # my $python_server_config = {

    # };
    # my $rpc_server_config = {
    #     perl   => $perl_server_config,
    #     python => $python_server_config,
    # };
    # my $rpc_server_mgr = FlowRPCServerManager->new($rpc_server_cmdlist, $debug);
    my $rpc_server_mgr = FlowRPCServerManager->new(undef, $debug);
    $rpc_server_mgr->launch_rpc_servers;

    my $test_flow_job = FlowJob->new("job1", "joba");
    my $test_flow_job2 = FlowJob->new("job3", "pyjoba");
    my $arg1 = "";
    my $arg2 = "";

    my $ret_test_rpc = $test_flow_job->test_rpc($arg1, $arg2);
    is("test rpc ret", $ret_test_rpc, "test rpc ret") or exit_test($rpc_server_mgr);
    # is("test rpc arg1 ret", $arg1, "test rpc arg1 ret") or done_testing;
    # is("test rpc arg2 ret", $arg2, "test rpc arg2 ret") or done_testing;

    my $ret_test_run = $test_flow_job->test_run($arg1, $arg2);
    is("test run ret", $ret_test_run, "test run ret") or exit_test($rpc_server_mgr);
    # is("test run arg1 ret", $arg1, "test run arg1 ret") or done_testing;
    # is("test run arg2 ret", $arg2, "test run arg2 ret") or done_testing;

    my $ret_test_call_python = $test_flow_job->test_call_python($arg1, $arg2, "");
    is("test call from perl", $ret_test_call_python, "test call python") or exit_test($rpc_server_mgr);
    

    # test python job
    $ret_test_rpc = $test_flow_job2->test_python_rpc($arg1, $arg2);
    is("test python rpc ret", $ret_test_rpc, "test rpc ret") or exit_test($rpc_server_mgr);
    # is("test rpc arg1 ret", $arg1, "test rpc arg1 ret") or done_testing;
    # is("test rpc arg2 ret", $arg2, "test rpc arg2 ret") or done_testing;

    $ret_test_run = $test_flow_job2->test_python_run($arg1, $arg2);
    is("test python run ret", $ret_test_run, "test run ret") or exit_test($rpc_server_mgr);
    # is("test run arg1 ret", $arg1, "test run arg1 ret") or done_testing;
    # is("test run arg2 ret", $arg2, "test run arg2 ret") or done_testing;

    $ret_test_run = $test_flow_job->test_log();

    exit_test($rpc_server_mgr);
}

&main;