use strict;
use warnings;
use JSON;
use Data::Dumper;
use FindBin qw/$Bin/;
use Getopt::Long qw(:config no_ignore_case);
use Test::More;

unshift @INC, "$Bin";
unshift @INC, "$Bin/../comm";
require "rpc_obj.pm";

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

    my $test_flow_job = FlowJob->new();
    my $arg1 = "";
    my $arg2 = "";

    if (lc($opts{l}) eq "perl") {
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
    } elsif (lc($opts{l}) eq "python") {
        my $ret_test_rpc = $test_flow_job->test_python_rpc($arg1, $arg2);
        is("test python rpc ret", $ret_test_rpc, "test rpc ret") or done_testing, return;
        # is("test rpc arg1 ret", $arg1, "test rpc arg1 ret") or done_testing;
        # is("test rpc arg2 ret", $arg2, "test rpc arg2 ret") or done_testing;

        my $ret_test_run = $test_flow_job->test_python_run($arg1, $arg2);
        is("test python run ret", $ret_test_run, "test run ret") or done_testing, return;
        # is("test run arg1 ret", $arg1, "test run arg1 ret") or done_testing;
        # is("test run arg2 ret", $arg2, "test run arg2 ret") or done_testing;
    }
    
    # sleep 10;

    &done_testing;
}

&main;