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
my $fc_msgs_config_json;

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

    $fc_msgs_config_json = "$basedir/fc_rpc/fc_msg/flow_controller_msg.json";

    $is_init = 1;
}

sub is_initialized {
    return $is_init;
}

sub get_fc_msgs_config_file {
    return $fc_msgs_config_json;
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


package RegisterCenter;

my $job_packages_routing_table = {};

my $api_routing_table = {};

sub register_job_package {
    my $job_package = shift;
    my $lang = shift;

    if (exists $job_packages_routing_table->{$job_package}) {
        my $cur_lang = $job_packages_routing_table->{$job_package};
        if ($cur_lang ne $lang) {
            # one job type has 2 implementations, it's illegal
            # TODO, print error msg and exit
        }
    } else {
        $job_packages_routing_table->{$job_package} = lc($lang);
    }
}

sub find_job_package {
    my $job_package = shift;

    return undef unless defined $job_package;

    if (exists $job_packages_routing_table->{$job_package}) {
        return $job_packages_routing_table->{$job_package};
    } else {
        return undef;
    }
}

sub register_api_module {
    my $module = shift;
    my $lang = shift;

    if (exists $api_routing_table->{$module}) {
        my $cur_lang = $api_routing_table->{$module};
        if ($cur_lang ne $lang) {
            # one module has 2 implementations, it's illegal
            # TODO, print error msg and exit
        } else {
            $api_routing_table->{$module} = lc($lang);
        }
    }
}

sub find_module {
    my $module = shift;

    return undef unless defined $module;

    if (exists $api_routing_table->{$module}) {
        return $api_routing_table->{$module};
    } else {
        return undef;
    }
}

1;