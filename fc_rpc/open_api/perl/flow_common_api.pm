use strict;
use warnings;
use Tie::Hash;

require "rpc.pm";

package JobAgent;

sub new {
    my $class = shift;
    my $name = shift;
    my $type = shift;

    my $obj = {};

    bless $obj, __PACKAGE__;

    return $obj;
}


package Tie::Hash::RPCFetch;

# TIEHASH classname, LIST
# FETCH this, key
# STORE this, key, value
# DELETE this, key
# CLEAR this
# EXISTS this, key
# FIRSTKEY this
# NEXTKEY this, lastkey
# SCALAR this
# DESTROY this
# UNTIE this

use base qw/Tie::StdHash/;

sub TIEHASH {
    my $class = shift;
    my $name = shift;
    my $type = shift;
    my $lang = shift;

    my $obj = {
        lang => $lang
    };

    bless $obj, $class;

    return $obj;
}

sub FETCH {
    my $self = shift;
    my $key = shift;

    my $name = $self->{name};
    my $lang = $self->{lang};

    # return $self->{$key} if exists $self->{$key};

    my $client = FC_RPC::get_client($lang);
    return $client->rpc_get_attr($name, $key);
}

sub STORE {
    my $self = shift;
    my $key = shift;
    my $value = shift;

    my $name = $self->{name};
    my $lang = $self->{lang};

    my $client = FC_RPC::get_client($lang);
    $client->rpc_set_attr($name, $key, $value);
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

    my $client = FC_RPC::get_client($lang);
    return $client->rpc_call($data);
}

1;