package App::Manoc::Utils::IPAddress;
#ABSTRACT: collection of functions to handle IP addresses

use strict;
use warnings;
##VERSION

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

=function check_addr($addr)

Return true if C<$addr> is a valid IPv4 address string.

=cut

sub check_addr {
    my $addr = shift;
    return if ( !defined($addr) );
    $addr =~ s/\s+//;
    return $addr =~ /^$RE{net}{IPv4}$/;
    #    return $addr =~ /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?\.?)((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){0,3}$/;
}

=function check_partial_addr($addr)

Return true if C<$addr> looks like a partial IPv4 address string.

=cut

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

=function check_ipv6_addr

NOT IMPLEMENTED YET

=cut

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

=function ip2int

Convert a string to an unsigned long (32-bit) in network order.

=cut

sub ip2int {
    return unless defined( $_[0] );
    return unpack( 'N', pack( 'C4', split( /\./, $_[0] ) ) );
}

=function int2ip

Convert an unsigned long (32-bit) in network order to a dotted notation ipaddres

=cut

sub int2ip {
    return unless defined( $_[0] );
    return join ".", unpack( "CCCC", pack( "N", $_[0] ) );
}

=function prefix2netmask_i

Convert a networkk prefix length to a netmask represented as an integer.

=cut

sub prefix2netmask_i {
    my $prefix = shift;
    ( $prefix >= 0 || $prefix <= 32 ) or
        croak "Invalid subnet prefix";

    return $prefix ? ~( ( 1 << ( 32 - $prefix ) ) - 1 ) : 0;
}

=function prefix2netmask

Convert a networkk prefix length to a netmask represented as a string.

=cut

sub prefix2netmask {
    my $prefix = shift;
    ( $prefix >= 0 || $prefix <= 32 ) or
        croak "Invalid subnet prefix";
    return int2ip( ~( ( 1 << ( 32 - $prefix ) ) - 1 ) );
}

=function prefix2wildcard

Convert a network prefix length to a network wildcard

=cut

sub prefix2wildcard {
    @_ == 1 || croak "Missing prefix parameter";
    my $prefix = shift;
    ( $prefix >= 0 || $prefix <= 32 ) or
        croak "Invalid subnet prefix";

    return int2ip( $prefix ? ( ( 1 << ( 32 - $prefix ) ) - 1 ) : 0xFFFFFFFF );
}

=function netmask2prefix

Convert a network netmask (as an ipv4 address string) to  prefix length.

 netmask2prefix("255.255.255.0"); # return 24

Return undef if input is not a valid netmask.

=cut

sub netmask2prefix {
    my $netmask = shift || croak "Missing netmask parameter";
    return $INET_NETMASK{ padded_ipaddr($netmask) };
}

=function padded_ipaddr

Return a zero padded representation of an IPv4 address string.

  padded_ipaddr("10.1.1.0"); # return "010.001.001.000"

Useful when storing ip addresses as strings in databases.

=cut

sub padded_ipaddr {
    my $addr = shift;
    defined($addr) or return;
    $addr =~ s/(^\.|\.$)//;
    $addr ne "" and join( '.', map { sprintf( '%03d', $_ ) } split( /\./, $addr ) );
}

=function unpadded_ipaddr

Remove zero padding from an IPv4 address string.

=cut

sub unpadded_ipaddr {
    my $addr = shift;
    join( '.', map { sprintf( '%d', $_ ) } split( /\./, $addr ) );
}

1;
