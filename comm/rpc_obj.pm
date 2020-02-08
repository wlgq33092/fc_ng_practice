use strict;
use warnings;

require "rpc.pm";
require "common.pm";

package FlowJob;

sub new {
    my $class = shift;
    my $name = shift;
    my $type = shift;

    my $instance = FlowRPCJob->new($name, $type);

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

    return $self->{instance}->test_rpc("perl", $arg1, $arg2);
}

sub test_run {
    my $self = shift;
    my $arg1 = shift;
    my $arg2 = shift;

    return $self->{instance}->test_run("perl", $arg1, $arg2);
}

sub test_call_python {
    my $self = shift;
    my $arg1 = shift;
    my $arg2 = shift;

    return $self->{instance}->test_call_python("perl", $arg1, $arg2, "");
}

sub test_python_rpc {
    my $self = shift;
    my $arg1 = shift;
    my $arg2 = shift;

    return $self->{instance}->test_rpc("python", $arg1, $arg2);
}

sub test_python_run {
    my $self = shift;
    my $arg1 = shift;
    my $arg2 = shift;

    return $self->{instance}->test_run("python", $arg1, $arg2);
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

    my $rpc_job = {
        name => $name,
        type => $type,
    };

    bless $rpc_job, __PACKAGE__;

    return $rpc_job;
}

sub AUTOLOAD {
    my $self = shift;
    my $lang = shift;
    $lang = lc($lang);
    my @args = @_;

    no strict 'vars';
    (my $method = $AUTOLOAD) =~ s{.*::}{};

    my $data = {
        job_name => "job1",
        job_type => "joba",
        method   => $method,
        args     => \@args,
    };

    $data->{job_type} = "pyjoba" if lc($lang) eq "python";
    $data->{job_name} = "job3" if lc($lang) eq "python";

    my $client = FlowContext::get_client($lang);
    return $client->rpc_call($data);
}

sub DESTROY {

}

1;