use strict;
use warnings;
use Socket;
use IO::Socket::UNIX;
use XML::LibXML;
use FindBin qw/$Bin/;
use threads;
use threads::shared;
use Thread::Queue;
use JSON;
use fc_msg;

require "common.pm";

our $flow_logger;

package FC_RPC;

sub rpc_print {
    my $content = shift;
    my $test_ref = shift;

    print STDERR "test rpc print: $content.\n";
    $test_ref = "changed by rpc print.\n";

    return "this is a return value from rpc_print.\n";
}

sub rpc_call_python {
    my $jobname = shift;
    my $jobtype = shift;
    my $method = shift;
    my @args = @_;

    my $call_data = {
        job_name => $jobname,
        job_type => $jobtype,
        method   => $method,
        args     => \@args,
    };

    # $flow_logger->log_debug("rpc call python: $jobname, $jobtype, $method.\n");

    my $client = get_client("python");

    return $client->rpc_call($call_data);
}

sub send_fc_message {
    my $sock = shift;
    my $msg = shift;
    my $peer = shift;

    $msg->print();
    my $send_data = $msg->serialization();
    # print &::Dumper($sock);
    $sock->send($send_data, 0);
}

sub recv_fc_message {
    my $conn = shift;

    my ($tag, $len, $val);

    eval {
        $conn->recv($tag, 4, 0);
        $conn->recv($len, 4, 0);
    };
    if ($@) {
        print STDERR "receive message error!";
        FlowContext::cleanup_flow_context();
    }
    
    return undef, undef, undef unless $tag and $len;
    
    $tag = unpack("N", $tag);
    $len = unpack("N", $len);
    # $flow_logger->log_debug("msg tag: $tag, msg len: $len\n");
    $conn->recv($val, $len, 0);
    return undef, undef, undef unless $val;
    # $flow_logger->log_debug("msg val: $val\n");
    $val = unpack("A*", $val);
    $val = JSON::decode_json($val);

    $flow_logger = &FlowContext::get_flow_logger;
    $flow_logger->log_info("msg tag: $tag, msg len: $len, val: $val\n");

    return ($tag, $len, $val);
}

# get an RPC client to the specified server
sub get_client {
    my $server = shift;
    $server = lc($server);

    my $sock_path = FlowContext::get_server_sock_path($server);
    print STDERR "perl get client: $server $sock_path\n";
    return undef unless defined $sock_path and -e $sock_path;

    my $client;
    eval {
        $client = FC_RPC_CLIENT->new($sock_path);
    };
    if ($@) {
        print STDERR "$server client is invalid, error: $@\n";
        FlowContext::cleanup_flow_context;
        FlowContext::flow_exit();
    }

    return $client;
}

# flow controller unix domain socket client in perl
package FC_RPC_CLIENT;

sub new {
    my $class = shift;
    my $sock_path = shift;

    my $sock = IO::Socket::UNIX->new(
        Type => ::SOCK_STREAM(),
        Peer => $sock_path,
    );

    unless (defined $sock) {
        FlowContext::cleanup_flow_context;
        FlowContext::flow_exit;
    }

    $sock->autoflush(1);

    my $cli = {
        sock_path => $sock_path,
        sock      => $sock,
    };

    bless $cli, __PACKAGE__;

    return $cli;
}

sub send_fc_message {
    my $self = shift;
    my $msg = shift;

    my $sock = $self->{sock};
    # $self->connect($self->{sock_path});
    # my $peer = $sock->peername;
    # print STDERR "send, peer: $peer\n";
    FC_RPC::send_fc_message($sock, $msg, $self->{sock_path});
}

sub recv_response {
    my $self = shift;
    my $conn = $self->{sock};

    return FC_RPC::recv_fc_message($conn);
}

sub _rpc {
    my $self = shift;
    my $tag = shift;
    my $call_data = shift;
    my $need_reply = shift;

    $need_reply = 1 unless defined $need_reply;

    my ($ret_tag, $ret_len, $ret_val);
    eval {
        my $call_msg = FCMessage->new($tag, $call_data);
        $self->send_fc_message($call_msg);
        ($ret_tag, $ret_len, $ret_val) = $self->recv_response if $need_reply;
    };
    if ($@) {
        print STDERR "run rpc error, error: $@.\n";
        FlowContext::cleanup_flow_context;
    }

    return ($ret_tag, $ret_len, $ret_val)
}

sub rpc_call {
    my $self = shift;
    my $call_data = shift;

    my ($tag, $len, $val) = $self->_rpc($FlowContext::FC_MSG_RPC, $call_data);
   
    $self->close();

    return $val->{return_val};
}

sub rpc_log {
    my $self = shift;
    my $logginglevel = shift;
    my $msg = shift;

    my $call_data = {
        logginglevel => $logginglevel,
        message      => $msg
    };

    my ($tag, $len, $val) = $self->_rpc($FlowContext::FC_MSG_LOG_PRINT, $call_data, 0);

    $self->close();
}

sub rpc_get_attr {
    my $self = shift;
    my $name = shift;
    my $attr = shift;

    my $data = {
        job_name => $name,
        attr     => $attr
    };

    my ($tag, $len, $val) = $self->_rpc($FlowContext::FC_MSG_GET_REMOTE_ATTR, $data);

    $self->close();

    return $val->{attr};
}

sub rpc_set_attr {
    my $self = shift;
    my $name = shift;
    my $attr = shift;
    my $val = shift;

    my $data = {
        job_name => $name,
        attr     => $attr,
        value    => $val,
    };

    $self->_rpc($FlowContext::FC_MSG_SET_REMOTE_ATTR, $data);

    $self->close();
}

sub rpc_create_job {
    my $self = shift;
    my $data = shift;

    $self->_rpc($FlowContext::FC_MSG_JOB_CREATE, $data);
    $self->close();
}

sub close {
    my $self = shift;
    my $conn = $self->{sock};

    $conn->close();
}

sub connect {
    my $self = shift;

    $self->{sock}->connect($self->{sock_path});
}

sub DESTROY {
    $_[0]->close();
}

package FC_RPC_SERVER;

sub new {
    my $self = shift;
    my $sock_path = shift;

    unlink $sock_path if -e $sock_path;

    my $sock = IO::Socket::UNIX->new(
        Type => ::SOCK_STREAM(),
        Local => $sock_path,
        Listen => 5,
    );

    my $server = {
        sock_path => $sock_path,
        sock      => $sock,
        conn      => undef,
    };

    bless $server, __PACKAGE__;

    return $server;
}

sub accept {
    my $self = shift;

    my $conn = $self->{sock}->accept;
    $self->{conn} = $conn;
}

sub get_request {
    my $self = shift;
    return undef unless defined $self->{conn};

    return FC_RPC::recv_fc_message($self->{conn});
}

sub send_response {
    my $self = shift;
    my $msg = shift;
    return undef unless defined $self->{conn};

    FC_RPC::send_fc_message($self->{conn}, $msg);
}

sub DESTROY {
    my $self = shift;
    unlink $self->{sock_path};
}

1;