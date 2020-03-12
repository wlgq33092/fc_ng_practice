use strict;
use warnings;
use JSON;

require "common.pm";

package FC_MSG_CONFIG;

my $fc_msgs;

sub new {
    my $class = shift;
    my $msg_config_file = shift;

    $msg_config_file = FlowContext::get_fc_msgs_config_file() unless defined $msg_config_file;
    my $msg_config = FlowContext::load_json_file($msg_config_file);

    my $obj = {
        config => $msg_config,
    };

    bless $obj, __PACKAGE__;

    $fc_msgs = $obj;

    return $obj;
}

sub get_fc_msgs_config {
    my $self = shift;

    if (defined $fc_msgs) {
        return $fc_msgs;
    } else {
        my $msg_config_file = FlowContext::get_fc_msgs_config_file();
        my $msg_config = FlowContext::load_json_file($msg_config_file);
        my $obj = {
            config => $msg_config,
        };
        bless $obj, __PACKAGE__;
        return $obj;
    }
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
    # $flow_logger->log_info("stwu debug: msg:\n" . "$msg->{value}\n");

    bless $msg, __PACKAGE__;

    $msg->check_valid();

    return $msg;
}

sub check_valid {
    my $self = shift;
    my $val = $self->{value_hash};

    # my $fc_msgs_config = FC_MSG_CONFIG::get_fc_msgs_config();

    # my $fc_msg_name2ids = $fc_msgs_config->{FC_MSG_IDS};
    # my $fc_msg_ids2name = reverse $fc_msg_name2ids;
    # my $msg_name = $fc_msg_ids2name->{$self->{tag}};
    # my $msg_config = $fc_msgs_config->{$msg_name};

    # check if msg config valid here
    # foreach my $key (keys %{$val}) {

    # }
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

sub print {
    my $self = shift;
    
    # print STDERR "perl msg: $self->{tag}\n";
    # foreach my $key (keys %{$self->{value_hash}}) {
    #     print STDERR "perl msg value: $key $self->{value_hash}->{$key}\n";
    # }
}

sub serialization {
    my $self = shift;
    $self->{value} = JSON::encode_json($self->{value_hash});
    $self->{msg_len} = length($self->{value});

    # $flow_logger->log_debug("msg serialization: tag: $self->{tag}, len: $self->{msg_len}, value: $self->{value}.\n");
    my $packed = pack("NNA*", $self->{tag}, $self->{msg_len}, $self->{value});
    
    return $packed;
}

1;