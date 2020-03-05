use strict;
use warnings;
use JSON;
use Data::Dumper;
use FindBin qw/$Bin/;
use Getopt::Long qw(:config no_ignore_case);
use Test::More;

use lib "$Bin";
use lib "$Bin/../comm";
use lib "$Bin/../fc_rpc/open_api/perl";
use lib "$Bin/../fc_rpc/perl_rpc";

require "log_agent.pm";
require "flow_common_api.pm";
require "test_util.pm";


sub exit_test {
    TestUtil::exit_test($_[0]);
}

sub main {
    my @opt_list = ("l=s");
    my %opts = TestUtil::get_test_opt(@opt_list);

    my $basedir = "/home/wuge/workspace/perl_workspace/flow_control_ng/";
    FlowContext::init_context($basedir);

    RegisterCenter::register_job_package("joba", "perl");
    RegisterCenter::register_job_package("pyjoba", "python");

    my $debug = undef;
    if (exists $opts{debug}) {
        if (lc($opts{debug}) eq 'perl' or lc($opts{debug}) eq 'python') {
            $debug = $opts{debug};
        }
    }
    my $rpc_server_cmdlist = {
        perl   => "$Bin/../fc_rpc/perl_rpc/perl_rpc_server.pl",
        python => "$Bin/../fc_rpc/python_rpc/python_rpc_server.py",
    };
    my $rpc_server_mgr = FlowRPCServerManager->new($rpc_server_cmdlist, $debug);
    # $rpc_server_mgr->launch_rpc_servers;

    my $logger = LogAgent->new("job1", "joba", 20);
    $logger->log_print("test log\n");
    $logger->log_debug("test log debug\n");
    # tie(my %logger, 'Tie::Hash::RPCFetch', 'job1');
    print STDERR $logger->{hello};
    # my $logger_ref = \%logger;
    # bless $logger_ref, 'Tie::Hash::RPCFetch';
    # bless $logger_ref, "LogAgent";
    # $logger_ref->log_print("hello!\n");


    # is(FlowContext::get_server_sock_path("perl"), "/home/wuge/.mytmp/unix-domain-socket-test-perl.sock", "test perl server sock path") or done_testing, return;
    # is(FlowContext::get_server_sock_path("python"), "/home/wuge/.mytmp/unix-domain-socket-test-python.sock", "test python server sock path") or done_testing, return;
    # is(FlowContext::get_server_sock_path("go"), undef, "test go server path") or done_testing, return;
    
    # &done_testing;
    exit_test($rpc_server_mgr);
}

&main;