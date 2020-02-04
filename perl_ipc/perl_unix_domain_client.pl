use strict;
use warnings;
use Socket;
use IO::Socket::UNIX;
# use XML::LibXML;
# use Getopt::Long qw(:config no_ignore_case);
use FindBin qw/$Bin/;
# use threads;
# use threads::shared;

sub main {
    unshift @INC, "$Bin/../comm";
    require "common.pm";

    my @pids;

    my $SOCK_PATH = "/home/wuge/.mytmp/unix-domain-socket-test.sock";

    my $client = IO::Socket::UNIX->new(
        Type => SOCK_STREAM(),
        Peer => $SOCK_PATH,
    );

    die "Create client error: $!" unless $client;

    $client->autoflush(1);

    my $req = "This is perl client!\n";
    my $packed_req = Common::serialization($req);
    $client->send($packed_req, 0);
    my $raw_data = "";
    $client->recv($raw_data, 32, 0);
    my $data = Common::deserialization($raw_data);
    print "receive from server: $data\n";
}

&main;