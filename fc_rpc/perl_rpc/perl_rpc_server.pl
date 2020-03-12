use strict;
use warnings;
use Socket;
use IO::Socket::UNIX;
use Getopt::Long qw(:config no_ignore_case);
use FindBin qw/$Bin/;
use lib "$Bin";
use lib "$Bin/../../comm";

use log_agent;
require "common.pm";

our $jobs = {};
our $flow_logger;

sub init_jobs {
    require "joba.pm";
    my $job1 = joba->new("job1", "joba");
    my $job2 = joba->new("job2", "joba");
    $jobs = {
        job1 => $job1,
        job2 => $job2,
    };
    return $jobs;
}

sub create_server {
    my $sock = FlowContext::get_server_sock_path("perl");
    my $server = FC_RPC_SERVER->new($sock);

    return $server;
}

sub simple_resp {
    my $ret = shift;

    my $response = {
        return_val => $ret,
    };

    no warnings "once";
    my $resp_msg = FCMessage->new($FlowContext::FC_MSG_RESP, $response);
    return $resp_msg;
}

sub handle_rpc_msg {
    my $req = shift;

    my $jobname = $req->{job_name};
    my $jobtype = $req->{job_type};
    my $method = $req->{method};
    my @args = @{$req->{args}};

    $flow_logger->log_debug("jobname: $jobname, type: $jobtype, method: $method.\n");
    my $job = $jobs->{$jobname};
    my $ret = $job->$method(@args);

    return simple_resp($ret);
}

sub handle_job_create_msg {
    my $req = shift;
    my $name = $req->{name};
    my $type = $req->{type};
    my $config = $req->{config};
    # TODO: need to tie req, get default value for optional field
    my $job_logging_level = $req->{logginglevel};

    my $logger = LogAgent->new($name, $job_logging_level);

    # build TflexJob here
    # find job package, require it and build job
    require "joba.pm";
    my $newjob = joba->new($name, "joba", $config, $logger);
    $jobs->{$name} = $newjob;

    return simple_resp("success");
}

sub handle_and_gen_resp {
    my $tag = shift;
    my $val = shift;

    no warnings "once";
    if ($tag == $FlowContext::FC_MSG_RPC) {
        return handle_rpc_msg($val);
    } elsif ($tag == $FlowContext::FC_MSG_JOB_CREATE) {
        return handle_job_create_msg($val);
    } else {
        return undef;
    }
}

sub main {
    my @opt_list = qw/root=s/;
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

    my $rootdir;
    if ($opts{root}) {
        $rootdir = $opts{root};
    } else {
        $rootdir = "$Bin/../../";
    }

    FlowContext::init_context($rootdir);

    require "rpc.pm";

    # $jobs = &init_jobs;
    # my $flow_log_file = $FlowContext::get_flow_log_file();
    $flow_logger = LogAgent->new("FLOW - Perl Server", 10);
    FlowContext::set_flow_logger($flow_logger);
    my $server = &create_server;

    while (1) {
        $flow_logger->log_info("perl language server is waiting for connection...\n");
        $server->accept;
        while (1) {
            my ($tag, $len, $val) = $server->get_request;
            last unless defined $tag;
            my $resp = handle_and_gen_resp($tag, $val);
            $server->send_response($resp);
        }
    }
}

&main;