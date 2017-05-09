package App::Manoc::Utils::Datetime;
#ABSTRACT: routines for managing timestamps and dates in Manoc

use strict;
use warnings;

##VERSION

BEGIN {
    use Exporter 'import';
    our @EXPORT_OK = qw/
        str2seconds print_timestamp
        /;
}

use Carp;

use POSIX qw(strftime);
use DateTime::Format::RFC3339;    # used for parse_datetime

=function str2seconds($str)

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
    $unit ||= 's';

    my %map = (
        's' => 1,
        'm' => 60,
        'h' => 3600,
        'd' => 86400,
        'w' => 604800,
        'M' => 2592000,
        'y' => 31536000
    );
    exists $map{$unit} or
        carp "Couldn't parse '$str'. Unknown unit $unit.";

    defined($num) or
        carp "Couldn't parse '$str'. Possible invalid syntax.";

    return $num * $map{$unit};
}

=function print_timestamp($timestamp)

Convert a unixtime stamp into a "%d/%m/%Y %H:%M:%S" string.

=cut

sub print_timestamp {
    my $timestamp = shift @_;
    defined($timestamp) || croak "Missing timestamp";
    my @timestamp = localtime($timestamp);
    return strftime( "%d/%m/%Y %H:%M:%S", @timestamp );
}

=function parse_datetime($str)

Parse a timestamp formatted according RFC 33339. Return a Date::Time object.

=cut

sub parse_datetime {
    my $str = shift;

    my $f  = DateTime::Format::RFC3339->new();
    my $dt = $f->parse_datetime($str);
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
