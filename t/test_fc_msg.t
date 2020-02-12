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
FlowContext::init_context("$Bin/../");

require "rpc_obj.pm";
require "fc_msg.pm";

sub test_tags_valid {
    my $config = shift;
    my $name = shift;
    my @expected_tags = @_;

    my @tags = ();
    foreach my $tag (keys %{$config}) {
        push @tags, $tag;
    }

    @tags = sort @tags;
    @expected_tags = sort @expected_tags;

    is_deeply(\@tags, \@expected_tags, "check $name tags");
}

sub test_tag {
    my $config = shift;
    my $name = shift;
    my $type = shift;
    my $optional = shift;

    is($type, $config->{type}, "$name type") or done_testing, exit 1;
    is($optional, $config->{optional}, "$name optional") or done_testing, exit 1;
}

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

    my $msg_config_file = "$Bin/../fc_rpc/fc_msg/flow_controller_msg.json";
    my $msg_config = FC_MSG_CONFIG->new($msg_config_file)->{config};

    my $msg_ids_conf = $msg_config->{FC_MSG_IDS};
    is("0", $msg_ids_conf->{MSG_TYPE_REQ}, "test msg id req") or done_testing, return;
    is("1", $msg_ids_conf->{MSG_TYPE_RESP}, "test msg id resp") or done_testing, return;
    is("2", $msg_ids_conf->{MSG_TYPE_RPC}, "test msg id rpc") or done_testing, return;
    is("3", $msg_ids_conf->{MSG_TYPE_CONFIG}, "test msg id config") or done_testing, return;

    my $msg_type_req = $msg_config->{MSG_TYPE_REQ};
    test_tags_valid($msg_type_req, "msg req", qw/job_type job_name method args/);
    test_tag($msg_type_req->{job_type}, "req job type", "string", "no");
    test_tag($msg_type_req->{job_name}, "req job name", "string", "no");
    test_tag($msg_type_req->{method}, "req method", "string", "no");
    test_tag($msg_type_req->{args}, "req args", "list", "yes");

    my $msg_type_resp = $msg_config->{MSG_TYPE_RESP};
    test_tags_valid($msg_type_resp, "msg resp", qw/return_val/);
    test_tag($msg_type_resp->{return_val}, "resp return val", "string", "no");

    my $msg_type_rpc = $msg_config->{MSG_TYPE_RPC};
    test_tags_valid($msg_type_rpc, "msg rpc", qw/module method args/);
    test_tag($msg_type_rpc->{module}, "rpc module", "string", "no");
    test_tag($msg_type_rpc->{method}, "rpc method", "string", "no");
    test_tag($msg_type_rpc->{args}, "rpc args", "list", "yes");

    &done_testing;
}

&main;