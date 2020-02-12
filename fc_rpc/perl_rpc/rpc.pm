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

    print STDERR "rpc call python: $jobname, $jobtype, $method.\n";

    my $client = FlowContext::get_client("python");

    return $client->rpc_call($call_data);
}

sub send_fc_message {
    my $sock = shift;
    my $msg = shift;
    my $peer = shift;

    my $send_data = $msg->serialization();
    # print &::Dumper($sock);
    $sock->send($send_data, 0, $peer);
}

sub recv_fc_message {
    my $conn = shift;

    my ($tag, $len, $val);

    $conn->recv($tag, 4, 0);
    $conn->recv($len, 4, 0);
    # eval {
    #     $conn->recv($tag, 4, 0);
    #     $conn->recv($len, 4, 0);
    # };
    return undef, undef, undef unless $tag and $len;
    
    $tag = unpack("N", $tag);
    $len = unpack("N", $len);
    print "msg tag: $tag, msg len: $len\n";
    $conn->recv($val, $len, 0);
    return undef, undef, undef unless $val;
    print "msg val: $val\n";
    $val = unpack("A*", $val);
    $val = JSON::decode_json($val);

    return ($tag, $len, $val);
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

sub rpc_call {
    my $self = shift;
    my $call_data = shift;

    # $self->connect($self->{sock_path});
    my $call_msg = FCMessage->new($FlowContext::MSG_TYPE_RPC, $call_data);
    $self->send_fc_message($call_msg);
    my ($tag, $len, $val) = $self->recv_response;

    $self->close();

    return $val->{return_val};
}

sub close {
    my $self = shift;
    my $conn = $self->{sock};

    $conn->close();
    # $conn->shutdown(2);
}

sub connect {
    my $self = shift;

    $self->{sock}->connect($self->{sock_path});
}

sub DESTROY {

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