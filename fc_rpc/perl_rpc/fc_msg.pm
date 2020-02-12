use strict;
use warnings;
use JSON;

require "common.pm";

package FC_MSG_CONFIG;

my $fc_msgs;

sub new {
    my $class = shift;
    my $msg_config_file = shift;

    # open MSG_CONFIG, "<$msg_config_file" or die "Open msg config file failed!\n";
    # my $config = "";
    # $config .= $_ while <MSG_CONFIG>;
    # close MSG_CONFIG;
    
    # my $msg_config = JSON::decode_json($config);
    my $msg_config = FlowContext::load_json_file($msg_config_file);

    my $obj = {
        config => $msg_config,
    };

    bless $obj, __PACKAGE__;

    $fc_msgs = $obj;

    return $obj;
}

sub AUTOLOAD {
    my $self = shift;
    my $attr = shift;

    my $config = $self->{config};
    
    no strict 'vars';
    (my $method = $AUTOLOAD) =~ s{.*::}{};

    if (exists $config->{$method}) {
        return $config->{$method}->{$attr};
    } else {
        return undef;
    }
}


# flow controller rpc message
# message:
# TLV
# tag(4 bytes, int) + len(4 bytes, int) + value(len bytes, string)
package FCMessage;

sub new {
    my $class = shift;
    my $tag = shift;
    my $value = shift;

    my $msg = {
        tag        => $tag,
        value_hash => $value,
        msg_len    => 0,
    };

    $msg->{value} = JSON::encode_json($value);
    print STDERR "stwu debug: msg:\n" . "$msg->{value}\n";

    bless $msg, __PACKAGE__;

    $msg->check_valid();

    return $msg;
}

sub check_valid {
    my $self = shift;
    my $val = $self->{value_hash};
}

sub set_value {
    my $self = shift;
    $self->{value_hash} = shift;
}

sub add_item {
    my $self = shift;
    my $key = shift;
    my $value = shift;

    $self->{value_hash}->{$key} = $value;
}

sub serialization {
    my $self = shift;
    $self->{value} = JSON::encode_json($self->{value_hash});
    $self->{msg_len} = length($self->{value});

    print STDERR "msg serialization: tag: $self->{tag}, len: $self->{msg_len}, value: $self->{value}.\n";
    my $packed = pack("NNA*", $self->{tag}, $self->{msg_len}, $self->{value});
    
    return $packed;
}

1;