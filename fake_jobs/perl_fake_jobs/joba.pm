use strict;
use warnings;

package joba;

sub new {
    my $self = shift;
    my $name = shift;
    my $type = shift;
    my $config = shift;
    my $logger = shift;

    my $job = {
        name   => $name,
        type   => $type,
        config => $config,
        logger => $logger,
    };

    bless $job, __PACKAGE__;

    return $job;
}

sub test_rpc {
    my $self = shift;
    my $arg1 = shift;
    my $arg2 = shift;

    my $logger = $self->{logger};
    $logger->log_print("perl run test rpc.", 20);
    $logger->log_info("perl run test rpc.");
    $logger->log_debug("perl run test rpc.");
    $logger->log_warning("perl run test rpc.");
    $logger->log_error("perl run test rpc.");

    return "test rpc ret";
}

sub test_log {
    my $self = shift;

    my $logger = $self->{logger};
    $logger->log_print("perl run test rpc log.", 20);
    $logger->log_info("perl run test rpc log.");
    $logger->log_debug("perl run test rpc log.");
    $logger->log_warning("perl run test rpc log.");
    $logger->log_error("perl run test rpc log.");

    return "test log ret";
}

sub test_run {
    my $self = shift;
    my $arg1 = shift;
    my $arg2 = shift;

    $arg1 = "test run arg1 ret";
    $arg2 = "test run arg2 ret";

    return "test run ret";
}

sub test_call_python {
    my $self = shift;
    my $arg1 = shift;
    my $arg2 = shift;
    my $arg3 = shift;

    return FC_RPC::rpc_call_python("job3", "pyjoba", "test_call_from_perl", $arg1, $arg2, $arg3);
}

1;