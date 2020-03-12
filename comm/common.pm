use strict;
use warnings;
use JSON;
use POSIX;
use FindBin qw/$Bin/;

use lib "$Bin";
use lib "$Bin/../fc_rpc/perl_rpc";
require "log_agent.pm";

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

sub load_json_file {
    my $json_file = shift;

    open JF, "<$json_file" or die "Open json file $json_file failed!\n";
    my $json_str = "";
    $json_str .= $_ while <JF>;
    close JF;
    
    return JSON::decode_json($json_str);
}


package FlowContextConfig;

sub new {
    my $class = shift;
    my $config_file = shift;

    my $fc_config_raw = Common::load_json_file($config_file);
    my $basedir = $fc_config_raw->{flow_basedir};

    my $obj = {
        basedir     => $basedir,
        config_file => $config_file,
        raw_config  => $fc_config_raw,
    };

    bless $obj, __PACKAGE__;

    return $obj;
}

sub replace_flow_basedir {
    my $self = shift;
    my $raw = shift;

    my $basedir = $self->{basedir};

    $raw =~ s/\$flow_basedir/$basedir/;

    # print STDERR "After replace: $raw.\n";

    return $raw;
}

sub DESTROY {}

sub AUTOLOAD {
    my $self = shift;

    no strict 'vars';
    (my $method = $AUTOLOAD) =~ s{.*::}{};
    if ($method =~ /^get_(.*)/) {
        print STDERR "Get: key: $1\n";
        if ($1 eq "rpc_server_config") {
            my $rpc_server_config;
            $rpc_server_config = $self->{raw_config}->{$1} if exists $self->{raw_config}->{$1};
            foreach my $server (keys %{$rpc_server_config}) {
                foreach my $key (keys %{$rpc_server_config->{$server}}) {
                    my $raw_value = $rpc_server_config->{$server}->{$key};
                    my $new_value = $self->replace_flow_basedir($raw_value);
                    $rpc_server_config->{$server}->{$key} = $new_value;
                }
            }
            return $rpc_server_config;
        } else {
            if (exists $self->{raw_config}->{$1}) {
                return $self->replace_flow_basedir($self->{raw_config}->{$1});
            } else {
                return undef;
            }
        }
    } else {
        print STDERR "Unknown subroutine $method in FlowContextConfig!\n";
    }
}

package FlowContext;

my $lang_server_sock_path = {
    perl   => "/home/wuge/.mytmp/unix-domain-socket-test-perl.sock",
    python => "/home/wuge/.mytmp/unix-domain-socket-test-python.sock",
    logger => "/home/wuge/.mytmp/unix-domain-socket-test-logger.sock",
};

my $lang_server_launch_cmd = {};

# my $basedir;
my $is_init = undef;
my $fc_config;
my $fc_msgs_config_json;
my $rpc_server_mgr;
my $flow_logger;

sub init_context {
    my $basedir = shift; # define basedir if flow controller engine
                         # basedir is undef if perl rpc server
    my $fc_config_json = shift;

    if (exists $ENV{FLOW_CONTEXT_CONFIG}) {
        # init perl rpc server
        $fc_config_json = $ENV{FLOW_CONTEXT_CONFIG} unless defined $fc_config_json;
        $fc_config = FlowContextConfig->new($fc_config_json);
        $basedir = $fc_config->get_flow_basedir;
    } else {
        # init flow controller engine, set env var FLOW_CONTEXT_CONFIG
        # FLOW_CONTEXT_CONFIG will be passed to rpc servers
        $basedir = ".." unless defined $basedir;
        $fc_config_json = "$basedir/comm/flow_context_config.json" unless defined $fc_config_json;
        $ENV{FLOW_CONTEXT_CONFIG} = $fc_config_json;
        $fc_config = FlowContextConfig->new($fc_config_json);
    }

    die "Don't have context config file $fc_config_json.\n" unless -e $fc_config_json;

    unshift @INC, "$basedir/fake_jobs/perl_fake_jobs";
    unshift @INC, "$basedir/fc_rpc/perl_rpc";
    unshift @INC, "$basedir/log_service";

    my $rpc_server_config = $fc_config->get_rpc_server_config;
    if (defined $rpc_server_config) {
        foreach my $server (keys %{$rpc_server_config}) {
            $lang_server_sock_path->{$server} = $rpc_server_config->{$server}->{sock_path};
        }
    }

    $fc_msgs_config_json = $fc_config->get_flow_message_config;
    &flow_exit("message config file $fc_msgs_config_json doesn't exist!\n") unless -e $fc_msgs_config_json;

    my $fc_msgs_config = Common::load_json_file($fc_msgs_config_json);
    my $msg_ids = $fc_msgs_config->{FC_MSG_IDS};
    foreach my $msg_type (keys %{$msg_ids}) {
        # print STDERR "set attr: type: $msg_type, value: $msg_ids->{$msg_type}.\n";
        no strict "refs";
        ${"FlowContext::" . $msg_type} = $msg_ids->{$msg_type};
    }

    # $flow_logger = LogAgent->new("FLOW - Engine", 10);

    $is_init = 1;
}

sub get_rpc_server_config {
    return $fc_config->get_rpc_server_config();
}

sub get_logger_service_info {
    return $fc_config->get_logger_service();
}

sub set_rpc_server_manager {
    $rpc_server_mgr = shift
}

sub get_rpc_server_manager {
    return $rpc_server_mgr;
}

sub is_initialized {
    return $is_init;
}

sub get_fc_msgs_config_file {
    return $fc_msgs_config_json;
}

sub get_server_sock_path {
    my $server_name = shift;

    return $lang_server_sock_path->{$server_name} if exists $lang_server_sock_path->{$server_name};
    return undef;
}

sub get_flow_log_file {
    return $fc_config->get_flow_log_file;
}

sub set_flow_logger {
    $flow_logger = shift;
}

sub get_flow_logger {
    return $flow_logger;
}

sub cleanup_flow_context {
    if (defined $rpc_server_mgr) {
        $rpc_server_mgr->kill_rpc_servers;
    }
}

sub flow_exit {
    my $self = shift;
    my $msg = shift;
    
    die "$msg" if defined $msg;
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

package FlowRPCServerManager;

# rpc_server_config is a hash ref
# { perl => $cmd1, python => $cmd2, logger => $cmd3 }
sub new {
    my $class = shift;
    my $rpc_server_config = shift;
    my $debug = shift; # which rpc server to debug, currently perl or python

    $rpc_server_config = &FlowContext::get_rpc_server_config unless defined $rpc_server_config;
    $debug = undef unless defined $debug and exists $rpc_server_config->{$debug};

    print STDERR "Debug rpc server: $debug.\n" if defined $debug;

    my $mgr = {
        rpc_server_config => $rpc_server_config,
        debug             => $debug,
        rpc_servers       => {}, # lang => pid
        pids              => [],
        debug_pid         => undef,
    };

    bless $mgr, __PACKAGE__;

    FlowContext::set_rpc_server_manager($mgr);

    return $mgr;
}

sub waiting_rpc_server_ready {
    my $self = shift;
    my $lang = shift;
    my $pid = shift;
    my $is_debugging = shift;

    my $sock_path = FlowContext::get_server_sock_path($lang);

    do {
        my $ret = waitpid($pid, POSIX::WNOHANG);
        if (0 == $ret) {
            return 1 if -e $sock_path;
        } else {
            return 0;
        }
    } while (1);
}

sub launch_rpc_process {
    my $self = shift;
    my $cmd = shift;
    my $start_debug = shift;

    my $pid = fork();
    if ($pid > 0) {
        push @{$self->{pids}}, $pid;
        return $pid;
    } elsif (0 == $pid) {
        print STDERR "Start rpc server, command: $cmd.\n";
        if (defined $start_debug) {
            if (POSIX::setsid() > 0) {
                my $child_pid = POSIX::getpid();
                print STDERR "Debugging process $child_pid.\n";
                POSIX::tcsetpgrp(0, $child_pid);
            } else {
                print STDERR "Launch debug mode failed, cmd: $cmd.\n";
            }
        }
        exec $cmd;
    } else {
        die "launch rpc server error, command: $cmd.\n";
    }
}

sub get_rpc_server_cmd {
    my $self = shift;
    my $server = shift;

    # print STDERR "get rpc server cmd: $server\n";
    # print STDERR "get rpc server: $_" foreach (keys %{$self->{rpc_server_config}->{$server}});
    my $bin = $self->{rpc_server_config}->{$server}->{bin_path};
    my $lang = $self->{rpc_server_config}->{$server}->{lang};
    my $cmd;
    if ($lang eq "perl") {
        $cmd = "perl " . $bin;
    } elsif ($lang eq "python") {
        $cmd = "python " . $bin;
    }

    return $cmd;
}

sub launch_rpc_server {
    my $self = shift;
    my $server = shift;
    
    $self->clean_sock_file($server);
    my $cmd = $self->get_rpc_server_cmd($server);
    my $pid = $self->launch_rpc_process($cmd);
    unless ($self->waiting_rpc_server_ready($server, $pid)) {
        $self->kill_rpc_servers;
        die "Start rpc server $server error.\n";
    }
    $self->{rpc_servers}->{$server} = $pid; 
}

sub launch_rpc_servers {
    my $self = shift;
    my $start_debug = shift;
    my $rpc_server_config = $self->{rpc_server_config};

    # launch logger service first
    $self->launch_rpc_server("logger");

    # Then launch normal rpc servers
    foreach my $server (keys %{$rpc_server_config}) {
        next if lc($server) eq "logger";   # logger service has been launched before
        next if defined $self->{debug} and lc($self->{debug}) eq lc($server);
        $self->launch_rpc_server($server);
    }

    # finally launch debug rpc server
    if ($self->{debug}) {
        my $pid = $self->debug_rpc_server;
        $self->{rpc_servers}->{$self->{debug}} = $pid;
    }
}

sub clean_sock_file {
    my $self = shift;
    my $lang = shift;
    my $sock_path = FlowContext::get_server_sock_path($lang);
    unlink $sock_path;
}

sub debug_rpc_server {
    my $self = shift;
    my $debug = $self->{debug};
    my $cmd = $self->{rpc_server_config}->{$debug}->{bin_path};

    if (lc($debug) eq "perl") {
        $cmd = "perl -d " . $cmd;
    } elsif (lc($debug) eq "python") {
        $cmd = "python -m pdb " . $cmd;
    } else {
        print STDERR "Unknown debug mode $debug.\n";
        exit 0;
    }

    $self->clean_sock_file($debug);

    my $pid = $self->{debug_pid} = $self->launch_rpc_process($cmd, 1);
    unless ($self->waiting_rpc_server_ready($debug, $pid)) {
        $self->kill_rpc_servers;
        die "Start rpc server $debug error.\n";
    }
}

sub wait_debug_proc {
    my $self = shift;
    my $debug_pid = $self->{debug_pid};

    my $ret = waitpid($debug_pid, 0);
    if ($ret == $debug_pid) {
        print STDERR "Wait debug proc $debug_pid success!\n";
    } else {
        print STDERR "Wait debug proc $debug_pid failed!\n";
    }
}

sub monitor_rpc_servers {
    my $self = shift;

    # TODO
    # blocking/non-blocking? waiting all rpc servers
}

# return how many servers didn't exit
sub check_rpc_servers {
    my $self = shift;
    my $debug_pid = $self->{debug_pid};

    # wait rpc servers nohang
    my $left = 0; # check how many servers remain
    my @pids = @{$self->{pids}};
    my @left = ();
    foreach my $pid (@pids) {
        if (defined $debug_pid) {
            next if $debug_pid == $pid;
        }
        my $ret = waitpid($pid, POSIX::WNOHANG);
        if ($pid == $ret) {
            print STDERR "Wait rpc server $pid exit successfully.\n";
        } else {
            $left += 1;
            push @left, $pid;
        }
    }

    $self->{pids} = \@left;

    return $left;
}

sub kill_rpc_servers {
    my $self = shift;
    my $debug_pid = $self->{debug_pid};

    # kill all rpc servers with sigterm(15)
    my @pids = @{$self->{pids}};
    foreach my $pid (@pids) {
        print STDERR "kill pid $pid.\n";
        kill 'TERM', $pid;
    }

    my $left = 0;
    do {
        $left = $self->check_rpc_servers;
    } while ($left > 0);
}

1;