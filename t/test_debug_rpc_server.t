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
    my $rpc_server_mgr = FlowRPCServerManager->new($rpc_server_cmdlist, "python");
    $rpc_server_mgr->launch_rpc_servers;

    # sleep 15;
    $rpc_server_mgr->kill_rpc_servers;
}

&main;