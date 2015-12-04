# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Utils::Datetime;
use strict;
use warnings;

BEGIN {
    use Exporter 'import';
    our @EXPORT_OK = qw/
        str2seconds print_timestamp
        /;
}

use Carp;

use POSIX qw(strftime);
use DateTime::Format::RFC3339;    # used for parse_datetime

=head1 DESCRIPTION

Manoc::Utils::Datetime - routines for managing timestamps and dates in Manoc

=cut

=head1 METHODS

=cut

=head2 str2seconds($str)

Parse a string made by an integer and a unit of time (e.g. h for
hours, M for months) and returns the equivalent number of seconds.

=cut

sub str2seconds {
    my ( $str, $unit ) = @_;
    croak "empty input string" unless defined $str;

    my ( $num, $unit2 ) = $str =~ m/^([+-]?\d+)([smhdwMy]?)$/;
    if ( $unit && $unit2 ) {
        warn "multiple units specified ($unit, $unit2)";
    }
    $unit //= $unit2;

    my %map = (
        's' => 1,
        'm' => 60,
        'h' => 3600,
        'd' => 86400,
        'w' => 604800,
        'M' => 2592000,
        'y' => 31536000
    );

    defined($num) or
        carp "couldn't parse '$str'. Possible invalid syntax";

    return $num * $map{$unit};
}

=head2 print_timestamp($timestamp)

Convert a unixtime stamp into a "%d/%m/%Y %H:%M:%S" string.

=cut

sub print_timestamp {
    my $timestamp = shift @_;
    defined($timestamp) || croak "Missing timestamp";
    my @timestamp = localtime($timestamp);
    return strftime( "%d/%m/%Y %H:%M:%S", @timestamp );
}

=head2 parse_datetime($str)

Parse a timestamp formatted according RFC 33339. Return a Date::Time object.

=cut

sub parse_datetime {
    my $str = shift;

    my $f  = DateTime::Format::RFC3339->new();
    my $dt = $f->parse_datetime($str);
}

=head1 LICENSE

Copyright 2011-2014 by the Manoc Team

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
