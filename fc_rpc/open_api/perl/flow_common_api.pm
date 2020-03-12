use strict;
use warnings;
use Tie::Hash;

require "rpc.pm";
require "common.pm";
require "log_agent.pm";

package RPCServerAPI;

sub get_job_instance_by_name {
    
}

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
    my $name = shift;  # used for prefix
    # my $type = "joba";
    my $type = shift;
    my $lang = RegisterCenter::find_job_package($type);
    print STDERR "name: $name, type: $type, lang: $lang\n";
    
    my $obj = {
        name => $name,
        lang => $lang
    };

    bless $obj, __PACKAGE__;

    return $obj;
}

sub log_print {
    my $self = shift;
    my $msg = shift;

    print STDERR "test tie hash: $msg";
}

sub FETCH {
    my $self = shift;
    my $key = shift;

    my $name = $self->{name};
    my $lang = $self->{lang};

    return "fetch name: $name, key: $key\n";
    # return $self->{$key} if exists $self->{$key};

    # my $client = FC_RPC::get_client($lang);
    # return $client->rpc_get_attr($name, $key);
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

    print STDERR "Run autoload in tie, method: $method\n";
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