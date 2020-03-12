use strict;
use warnings;
use JSON;
use Data::Dumper;
use FindBin qw/$Bin/;
use Getopt::Long qw(:config no_ignore_case);
use Test::More;

use lib "$Bin";
use lib "$Bin/../comm";
use lib "$Bin/../fc_rpc/open_api/perl";
use lib "$Bin/../fc_rpc/perl_rpc";

package TestUtil;

sub exit_test {
    my $rpc_server_mgr = shift;
    $rpc_server_mgr->kill_rpc_servers;
    &::done_testing;
    exit 0;
}

sub get_test_opt {
    my @opt_list = @_;
    my %opts;

    $SIG{__WARN__} = sub {
        my $wng = shift;
        my $msg = $wng;
        $msg =~ s/Unknown option/Unknown command line option/g;
        chomp $msg;
        print "$msg, please check command line argument.\n";
        exit 1;
    };

    ::GetOptions(\%opts, @opt_list);
    $SIG{__WARN__} = 'DEFAULT';

    return %opts;
}

1;