use strict;
use warnings;
use JSON;
use POSIX;

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

our $FC_MSG_REQ = 0;
our $FC_MSG_RESP = 1;
our $FC_MSG_RPC = 2;

my $lang_server_sock_path = {
    perl   => "/home/wuge/.mytmp/unix-domain-socket-test-perl.sock",
    python => "/home/wuge/.mytmp/unix-domain-socket-test-python.sock",
};

# my $basedir;
my $is_init = undef;
my $fc_config;
my $fc_msgs_config_json;
my $rpc_server_mgr;

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

sub cleanup_flow_context {
    if (defined $rpc_server_mgr) {
        $rpc_server_mgr->kill_rpc_servers;
    }
}

sub flow_exit {
    exit 0;
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

# cmdlist is a hash ref
# { perl => $cmd1, python => $cmd2 }
sub new {
    my $class = shift;
    my $cmdlist = shift;
    my $debug = shift; # which rpc server to debug, currently perl or python

    $debug = undef unless exists $cmdlist->{$debug};

    print STDERR "Debug rpc server: $debug.\n" if defined $debug;

    my $mgr = {
        cmdlist     => $cmdlist,
        debug       => $debug,
        rpc_servers => {}, # lang => pid
        pids        => [],
        debug_pid   => undef,
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

sub launch_rpc_server {
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

sub launch_rpc_servers {
    my $self = shift;
    my $start_debug = shift;
    my $cmdlist = $self->{cmdlist};

    foreach my $lang (keys %{$cmdlist}) {
        next if lc($self->{debug}) eq lc($lang);
        $self->clean_sock_file($lang);
        my $cmd = $cmdlist->{$lang};
        $cmd = "perl " . $cmd if lc($lang) eq "perl";
        $cmd = "python " . $cmd if lc($lang) eq "python";
        my $pid = $self->launch_rpc_server($cmd);
        unless ($self->waiting_rpc_server_ready($lang, $pid)) {
            $self->kill_rpc_servers;
            die "Start rpc server $lang error.\n";
        }
        $self->{rpc_servers}->{$lang} = $pid; 
    }

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
    my $cmd = $self->{cmdlist}->{$debug};

    if (lc($debug) eq "perl") {
        $cmd = "perl -d " . $cmd;
    } elsif (lc($debug) eq "python") {
        $cmd = "python -m pdb " . $cmd;
    } else {
        print STDERR "Unknown debug mode $debug.\n";
        exit 0;
    }

    $self->clean_sock_file($debug);

    my $pid = $self->{debug_pid} = $self->launch_rpc_server($cmd, 1);
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
    # block waiting all rpc servers
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