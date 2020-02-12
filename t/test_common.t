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

    my $basedir = "/home/wuge/workspace/perl_workspace/flow_control_ng/";
    FlowContext::init_context($basedir);

    is(FlowContext::get_server_sock_path("perl"), "/home/wuge/.mytmp/unix-domain-socket-test-perl.sock", "test perl server sock path") or done_testing, return;
    is(FlowContext::get_server_sock_path("python"), "/home/wuge/.mytmp/unix-domain-socket-test-python.sock", "test python server sock path") or done_testing, return;
    is(FlowContext::get_server_sock_path("go"), undef, "test go server path") or done_testing, return;
    
    &done_testing;
}

&main;