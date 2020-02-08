use strict;
use warnings;

package joba;

sub new {
    my $self = shift;
    my $name = shift;
    my $type = shift;
    my $job = {};

    bless $job, __PACKAGE__;

    return $job;
}

sub test_rpc {
    my $self = shift;
    my $arg1 = shift;
    my $arg2 = shift;

    return "test rpc ret";
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