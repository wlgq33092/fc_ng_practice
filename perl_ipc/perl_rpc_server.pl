use strict;
use warnings;
use Socket;
use IO::Socket::UNIX;
# use XML::LibXML;
# use Getopt::Long qw(:config no_ignore_case);
use FindBin qw/$Bin/;
# use threads;
# use threads::shared;

unshift @INC, "$Bin/../comm";
unshift @INC, "$Bin";
require "common.pm";
require "joba.pm";

our $jobs = {};

sub init_jobs {
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

sub handle_rpc_msg {
    my $req = shift;

    my $jobname = $req->{job_name};
    my $jobtype = $req->{job_type};
    my $method = $req->{method};
    my @args = @{$req->{args}};

    print STDERR "jobname: $jobname, type: $jobtype, method: $method.\n";
    my $job = $jobs->{$jobname};
    my $ret = $job->$method(@args);

    my $response = {
        return_val => $ret,
    };

    my $resp_msg = FCMessage->new($FlowContext::MSG_TYPE_RESP, $response);
    return $resp_msg;
}

sub handle_and_gen_resp {
    my $tag = shift;
    my $val = shift;

    if ($tag == $FlowContext::MSG_TYPE_RPC) {
        handle_rpc_msg($val);
    } else {
        return undef;
    }
}

sub main {
    unshift @INC, "$Bin/../comm";
    require "common.pm";

    $jobs = &init_jobs;
    my $server = &create_server;

    while (1) {
        print STDERR "perl language server is waiting for connection...\n";
        $server->accept;
        while (1) {
            my ($tag, $len, $val) = $server->get_request;
            last unless defined $tag;
            my $resp = handle_and_gen_resp($tag, $val);
            $server->send_response($resp);
        }
        # my $pid = fork();
        # if (0 == $pid) {
        #     1;
        # } elsif ($pid > 0) {
        #     while (1) {
        #         my ($tag, $len, $val) = $server->get_request;
        #         last unless defined $tag;
        #         my $resp = handle_and_gen_resp($tag, $val);
        #         $server->send_response($resp);
        #     }
        # } 
    }
}

&main;