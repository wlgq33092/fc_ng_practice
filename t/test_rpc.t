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

sub main {
    my @opt_list = ("l=s");
    my %opts;

    $SIG{__WARN__} = sub {
        my $wng = shift;
        my $msg = $wng;
        $msg =~ s/Unknown option/Unknown command line option/g;
        chomp $msg;
        print "$msg, please check command line argument.\n";
        exit 1;
    };

    my $ret = GetOptions(\%opts, @opt_list);
    $SIG{__WARN__} = 'DEFAULT';

    FlowContext::init_context("$Bin/../");

    require "rpc_obj.pm";

    RegisterCenter::register_job_package("joba", "perl");
    RegisterCenter::register_job_package("pyjoba", "python");

    my $rpc_server_cmdlist = {
        perl   => "$Bin/../fc_rpc/perl_rpc/perl_rpc_server.pl",
        python => "$Bin/../fc_rpc/python_rpc/python_rpc_server.py",
    };
    my $rpc_server_mgr = FlowRPCServerManager->new($rpc_server_cmdlist, undef);
    $rpc_server_mgr->launch_rpc_servers;

    my $test_flow_job = FlowJob->new("job1", "joba");
    my $test_flow_job2 = FlowJob->new("job3", "pyjoba");
    my $arg1 = "";
    my $arg2 = "";

    my $ret_test_rpc = $test_flow_job->test_rpc($arg1, $arg2);
    is("test rpc ret", $ret_test_rpc, "test rpc ret") or done_testing, return;
    # is("test rpc arg1 ret", $arg1, "test rpc arg1 ret") or done_testing;
    # is("test rpc arg2 ret", $arg2, "test rpc arg2 ret") or done_testing;

    my $ret_test_run = $test_flow_job->test_run($arg1, $arg2);
    is("test run ret", $ret_test_run, "test run ret") or done_testing, return;
    # is("test run arg1 ret", $arg1, "test run arg1 ret") or done_testing;
    # is("test run arg2 ret", $arg2, "test run arg2 ret") or done_testing;

    my $ret_test_call_python = $test_flow_job->test_call_python($arg1, $arg2, "");
    is("test call from perl", $ret_test_call_python, "test call python") or done_testing, return;
    
    $ret_test_rpc = $test_flow_job2->test_python_rpc($arg1, $arg2);
    is("test python rpc ret", $ret_test_rpc, "test rpc ret") or done_testing, return;
    # is("test rpc arg1 ret", $arg1, "test rpc arg1 ret") or done_testing;
    # is("test rpc arg2 ret", $arg2, "test rpc arg2 ret") or done_testing;

    $ret_test_run = $test_flow_job2->test_python_run($arg1, $arg2);
    is("test python run ret", $ret_test_run, "test run ret") or done_testing, return;
    # is("test run arg1 ret", $arg1, "test run arg1 ret") or done_testing;
    # is("test run arg2 ret", $arg2, "test run arg2 ret") or done_testing;
    
    &done_testing;

    $rpc_server_mgr->kill_rpc_servers;
}

&main;