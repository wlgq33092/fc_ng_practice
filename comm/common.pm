use strict;
use warnings;
use JSON;

require "rpc.pm";

package Common;

sub serialization {
    my $raw = shift;
    my $len = length($raw);

    my $packed = pack("NNA*", 1, $len, $raw);
    print STDERR "serialization raw: $raw, len: $len, packed: $packed\n";

    return $packed;
}

sub deserialization {
    my $raw = shift;
    my ($len, $line) = unpack("NA*", $raw);
    print STDERR "deserialization: raw: $raw, len: $len, unpack: $line\n";

    return $line;
}

sub get_msg {
    my $conn = shift;
    my ($tag, $len, $val);
    $conn->recv($tag, 4, 0);
    $conn->recv($len, 4, 0);
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

package FlowContext;

our $MSG_TYPE_REQ = 0;
our $MSG_TYPE_RESP = 1;
our $MSG_TYPE_RPC = 2;

my $lang_server_sock_path = {
    perl   => "/home/wuge/.mytmp/unix-domain-socket-test-perl.sock",
    python => "/home/wuge/.mytmp/unix-domain-socket-test-python.sock",
};

my $clients = {};

sub get_server_sock_path {
    my $server_name = shift;

    return $lang_server_sock_path->{$server_name} if exists $lang_server_sock_path->{$server_name};
    return undef;
}

sub get_client {
    my $server = shift;
    $server = lc($server);

    return undef unless exists $lang_server_sock_path->{$server};
    # return $clients->{$server} if exists $clients->{$server};

    my $client = FC_RPC_CLIENT->new($lang_server_sock_path->{$server});
    $clients->{$server} = $client;

    # $client->connect();

    return $client;
}


1;