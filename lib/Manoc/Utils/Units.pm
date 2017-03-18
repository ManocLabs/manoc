# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Utils::Units;
use strict;
use warnings;

BEGIN {
    use Exporter 'import';
    our @EXPORT_OK = qw/
        parse_storage_size
        /;
}

use Carp;

=head1 DESCRIPTION

Manoc::Utils::Units - routines for managing unit of measure

=cut

=head1 FUNCTIONS

=cut

=head2 parse_storage_size($str, [$unit])

Parse a string made by an integer and a unit of time (e.g. h for
hours, M for months) and returns the equivalent number of seconds.

=cut

sub parse_storage_size {
    my ( $str, $unit ) = @_;
    croak "empty input string" unless defined $str;
    my ( $num, $unit2 ) = $str =~ m/^([+-]?\d+)\s*((.*[bB]?)|[KGTPE])$/;
    if ( $unit && $unit2 ) {
        warn "multiple units specified ($unit, $unit2)";
    }
    $unit //= $unit2;
    $unit ||= 'B';

    # use uppercase keys
    my %map = (
        'B' => 1,
        # kilobyte
        'KB' => 1000,
        # kibibyte
        'KIB' => 1024,
        # megabite
        'MB' => 1_000_000,
        # mebibyte
        'M'   => 1_048_576,
        'MiB' => 1_048_576,
        # gigabyte
        'GB' => 1_000_000_000,
        # gibibyte
        'G'   => 1_073_741_824,
        'GiB' => 1_073_741_824,
        # terabyte
        'TB' => 1_000_000_000_000,
        # tebibyte
        'T'   => 1_099_511_627_776,
        'TiB' => 1_099_511_627_776,
        # petabyte
        'PB' => 1_000_000_000_000_000,
        # pebibyte
        'P'   => 1_125_899_906_842_624,
        'PiB' => 1_125_899_906_842_624,
        #exabyte
        'EB' => 1_000_000_000_000_000_000,
        # exbibyte
        'B'   => 1_152_921_504_606_846_976,
        'EiB' => 1_152_921_504_606_846_976,
    );
    exists $map{ uc($unit) } or
        carp "Couldn't parse '$str'. Unknown unit $unit.";

    defined($num) or
        carp "Couldn't parse '$str'. Possible invalid syntax.";

    return $num * $map{ uc($unit) };
}

=head1 LICENSE

Copyright 2011- by the Manoc Team

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
