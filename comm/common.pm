use strict;
use warnings;
use JSON;

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

package FlowContext;

our $MSG_TYPE_REQ = 0;
our $MSG_TYPE_RESP = 1;
our $MSG_TYPE_RPC = 2;

my $lang_server_sock_path = {
    perl   => "/home/wuge/.mytmp/unix-domain-socket-test-perl.sock",
    python => "/home/wuge/.mytmp/unix-domain-socket-test-python.sock",
};

# my $basedir;
my $is_init = undef;
my $fc_config;

sub init_context {
    my $basedir = shift;
    my $fc_config_json = shift;

    $basedir = "../" unless defined $basedir;
    $fc_config_json = "$basedir/comm/flow_context_config.json" unless defined $fc_config_json;

    unshift @INC, "$basedir/fake_jobs/perl_fake_jobs";
    unshift @INC, "$basedir/fc_rpc/perl_rpc";
    unshift @INC, "$basedir/log_service";

    $fc_config = load_json_file($fc_config_json);
    if (exists $fc_config->{rpc_server_sock_path}) {
        foreach my $lang (keys %{$fc_config->{rpc_server_sock_path}}) {
            $lang_server_sock_path->{$lang} = $fc_config->{rpc_server_sock_path}->{$lang}
        }
    }

    $is_init = 1;
}

sub is_initialized {
    return $is_init;
}

sub load_json_file {
    my $json_file = shift;

    open JF, "<$json_file" or die "Open json file $json_file failed!\n";
    my $json_str = "";
    $json_str .= $_ while <JF>;
    close JF;
    
    return JSON::decode_json($json_str);
}

sub get_server_sock_path {
    my $server_name = shift;

    return $lang_server_sock_path->{$server_name} if exists $lang_server_sock_path->{$server_name};
    return undef;
}

1;