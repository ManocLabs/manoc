# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Utils::IPAddress;

use strict;
use warnings;
use Carp;
use Regexp::Common qw/net/;

BEGIN {
    use Exporter 'import';
    our @EXPORT_OK = qw(
        ip2int int2ip
        netmask_prefix2range netmask2prefix
        padded_ipaddr unpadded_ipaddr
        prefix2wildcard prefix2netmask prefix2netmask_i
        check_addr check_partial_addr check_ipv6_addr
    );

}

sub check_addr {
    my $addr = shift;
    return if ( !defined($addr) );
    $addr =~ s/\s+//;
    return $addr =~ /^$RE{net}{IPv4}$/;
    #    return $addr =~ /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?\.?)((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){0,3}$/;
}

sub check_partial_addr {
    my $addr = shift;
    return if ( !defined($addr) );
    $addr =~ s/\s+//;

    if ( $addr =~ /^([0-9\.]+\.)$/o or
        $addr =~ /^(\.[0-9\.]+)$/o or
        $addr =~ /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/o )
    {
        return 1;
    }
}

#N.B. must be implemented
sub check_ipv6_addr {
    die "Not implemented";
}

my %INET_NETMASK = (
    '000.000.000.000' => 0,
    '128.000.000.000' => 1,
    '192.000.000.000' => 2,
    '224.000.000.000' => 3,
    '240.000.000.000' => 4,
    '248.000.000.000' => 5,
    '252.000.000.000' => 6,
    '254.000.000.000' => 7,
    '255.000.000.000' => 8,
    '255.128.000.000' => 9,
    '255.192.000.000' => 10,
    '255.224.000.000' => 11,
    '255.240.000.000' => 12,
    '255.248.000.000' => 13,
    '255.252.000.000' => 14,
    '255.254.000.000' => 15,
    '255.255.000.000' => 16,
    '255.255.128.000' => 17,
    '255.255.192.000' => 18,
    '255.255.224.000' => 19,
    '255.255.240.000' => 20,
    '255.255.248.000' => 21,
    '255.255.252.000' => 22,
    '255.255.254.000' => 23,
    '255.255.255.000' => 24,
    '255.255.255.128' => 25,
    '255.255.255.192' => 26,
    '255.255.255.224' => 27,
    '255.255.255.240' => 28,
    '255.255.255.248' => 29,
    '255.255.255.252' => 30,
    '255.255.255.254' => 31,
    '255.255.255.255' => 32,
);

# functions

sub ip2int {
    return unpack( 'N', pack( 'C4', split( /\./, $_[0] ) ) );
}

sub int2ip {
    return join ".", unpack( "CCCC", pack( "N", $_[0] ) );
}

sub prefix2netmask_i {
    my $prefix = shift;
    ( $prefix >= 0 || $prefix <= 32 ) or
        croak "Invalid subnet prefix";

    return $prefix ? ~( ( 1 << ( 32 - $prefix ) ) - 1 ) : 0;
}

sub prefix2wildcard {
    @_ == 1 || croak "Missing prefix parameter";
    my $prefix = shift;
    ( $prefix >= 0 || $prefix <= 32 ) or
        croak "Invalid subnet prefix";

    return int2ip( $prefix ? ( ( 1 << ( 32 - $prefix ) ) - 1 ) : 0xFFFFFFFF );
}

sub padded_ipaddr {
    my $addr = shift;
    defined($addr) or return;
    $addr =~ s/(^\.|\.$)//;
    $addr ne "" and join( '.', map { sprintf( '%03d', $_ ) } split( /\./, $addr ) );
}

sub unpadded_ipaddr {
    my $addr = shift;
    join( '.', map { sprintf( '%d', $_ ) } split( /\./, $addr ) );
}

sub prefix2netmask {
    my $prefix = shift;
    ( $prefix >= 0 || $prefix <= 32 ) or
        croak "Invalid subnet prefix";
    return int2ip( ~( ( 1 << ( 32 - $prefix ) ) - 1 ) );
}

sub netmask2prefix {
    my $netmask = shift || croak "Missing netmask parameter";
    return $INET_NETMASK{ padded_ipaddr($netmask) };
}

1;
