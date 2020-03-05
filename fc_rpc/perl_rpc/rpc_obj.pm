use strict;
use warnings;

require "rpc.pm";
require "common.pm";

package FlowJob;

sub new {
    my $class = shift;
    my $name = shift;
    my $type = shift;
    my $config = shift;

    my $instance = FlowRPCJob->new($name, $type, $config);

    my $obj = {
        name     => $name,
        type     => $type,
        instance => $instance,
    };

    bless $obj, __PACKAGE__;

    return $obj;
}

sub test_rpc {
    my $self = shift;
    my $arg1 = shift;
    my $arg2 = shift;

    return $self->{instance}->test_rpc($arg1, $arg2);
}

sub test_run {
    my $self = shift;
    my $arg1 = shift;
    my $arg2 = shift;

    return $self->{instance}->test_run($arg1, $arg2);
}

sub test_call_python {
    my $self = shift;
    my $arg1 = shift;
    my $arg2 = shift;

    return $self->{instance}->test_call_python($arg1, $arg2, "");
}

sub test_python_rpc {
    my $self = shift;
    my $arg1 = shift;
    my $arg2 = shift;

    return $self->{instance}->test_rpc($arg1, $arg2);
}

sub test_python_run {
    my $self = shift;
    my $arg1 = shift;
    my $arg2 = shift;

    return $self->{instance}->test_run($arg1, $arg2);
}

sub AUTOLOAD {
    # return undef;

    my $self = shift;
    my @args = @_;

    no strict 'vars';
    (my $method = $AUTOLOAD) =~ s{.*::}{};

    return $self->{instance}->$method(@args);
}


# job instance for flow job in flow controller next generation
package FlowRPCJob;

sub new {
    my $self = shift;
    my $name = shift;
    my $type = shift;
    my $config = shift;

    my $rpc_job = {
        name   => $name,
        type   => $type,
        config => $config,
    };

    my $lang = RegisterCenter::find_job_package($type);
    my $client = FC_RPC::get_client($lang);
    $client->rpc_create_job($rpc_job);

    bless $rpc_job, __PACKAGE__;

    return $rpc_job;
}

sub AUTOLOAD {
    my $self = shift;
    my @args = @_;

    my $lang = RegisterCenter::find_job_package($self->{type});

    no strict 'vars';
    (my $method = $AUTOLOAD) =~ s{.*::}{};

    my $data = {
        job_name => $self->{name},
        job_type => $self->{type},
        method   => $method,
        args     => \@args,
    };

    # $data->{job_type} = "pyjoba" if lc($lang) eq "python";
    # $data->{job_name} = "job3" if lc($lang) eq "python";

    my $client = FC_RPC::get_client($lang);
    return $client->rpc_call($data);
}

sub DESTROY {

}

1;