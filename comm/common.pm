use strict;
use warnings;

package Common;

sub serialization {
    my $raw = shift;
    my $len = length($raw);

    my $packed = pack("NA*", $len, $raw);
    print STDERR "serialization raw: $raw, len: $len, packed: $packed\n";

    return $packed;
}

sub deserialization {
    my $raw = shift;
    my ($len, $line) = unpack("NA*", $raw);
    print STDERR "deserialization: raw: $raw, len: $len, unpack: $line\n";

    return $line;
}

1;