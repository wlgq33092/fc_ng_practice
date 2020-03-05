use strict;
use warnings;

require "rpc.pm";
require "common.pm";

package LogAgent;

my $DEV = 10;
my $INFO = 20;
my $WARNING = 30;
my $ERROR = 40;

my $logging_prefix = {
    10 => "DEV",
    20 => "INFO",
    30 => "WARNING",
    40 => "ERROR"
};

sub new {
    my $class = shift;
    my $name = shift; # for prefix
    my $level = shift;

    my $logger = {
        name  => $name,
        level => $level,
    };

    # tie(%logger, "Tie::Hash::RPCFetch", $name, $type);

    # my $logger_ref = \%logger;

    bless $logger, __PACKAGE__;

    return $logger;
}

sub log_print {
    my $self = shift;
    my $msg = shift;
    my $level = shift;

    # if input logging level is invalid, use the same as configured logging level
    $level = $self->{level} 
        unless $level == 10 or $level == 20 or $level == 30 or $level == 40;
    
    # if input level bigger than job logginglevel,
    # return directly
    return if $level > $self->{level};

    my $name = $self->{name};
    my $logging_prefix = $self->get_logging_prefix($level);

    $msg = "[$logging_prefix][$name]: $msg";

    my $client = FC_RPC::get_client("python");
    $client->rpc_log($INFO, $msg);
}

sub get_logging_prefix {
    my $self = shift;
    my $level = shift; # caller guarantee $level is 10 or 20 or 30 or 40

    return $logging_prefix->{$level};
}

sub log_info {
    $_[0]->log_print($_[1], $INFO);
}

sub log_error {
    $_[0]->log_print($_[1], $ERROR);
}

sub log_debug {
    $_[0]->log_print($_[1], $DEV);
}

sub log_warning {
    $_[0]->log_print($_[1], $WARNING);
}

sub AUTOLOAD {
    # my $self = shift;
    # my @args = @_;

    # my $lang = RegisterCenter::find_job_package($self->{type});

    # no strict 'vars';
    # (my $method = $AUTOLOAD) =~ s{.*::}{};

    # print STDERR "Run log agent autoload! method: $method\n";
    # my $data = {
    #     job_name => $self->{name},
    #     job_type => $self->{type},
    #     method   => $method,
    #     args     => \@args,
    # };

    # my $client = FC_RPC::get_client($lang);
    # return $client->rpc_call($data);
}

1;