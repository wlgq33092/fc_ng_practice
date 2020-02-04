use strict;
use warnings;
use Socket;
use IO::Socket::UNIX;
use XML::LibXML;
use Getopt::Long qw(:config no_ignore_case);
use FindBin qw/$Bin/;
use threads;
use threads::shared;

sub main {
    unshift @INC, "$Bin/../comm";
    require "common.pm";

    my @opt_list = ("d=s");
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

    my $SOCK_PATH = "/home/wuge/.mytmp/unix-domain-socket-test.sock";
    my $MAX_LISTEN_NUM = 5;

    my $server = IO::Socket::UNIX->new(
        Type => SOCK_STREAM(),
        Local => $SOCK_PATH,
        Listen => $MAX_LISTEN_NUM,
    );

    die "can't create socket: $!" unless $server;

    # my $sel = IO::Select->new();
    # $sel->add($server);
    
    my @connections = ();
    my $thread_accept = threads->create( sub {
        my $sock = shift;
        my $max_listen_num = shift;

        my @conns = ();
        for (1 .. $max_listen_num) {
            my $conn = $sock->accept;
            $conn->autoflush(1);
            push @connections, $conn;
            print "connect failed!\n" unless $conn;

            while (1) {
                my $raw = "";
                $conn->recv($raw, 32, 0);
                last unless $raw;
                my $line = Common::deserialization($raw);
                print "test: $line\n";
                my $response = "Response from server.\n";
                my $packed_resp = Common::serialization($response);
                $conn->send($packed_resp, 0);
            }
        }

        return @connections;
    }, $server, 1);

    @connections = $thread_accept->join();

    print "end of server\n";

    unlink $SOCK_PATH;
}

&main;