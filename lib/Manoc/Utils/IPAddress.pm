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
      prefix2wildcard
      check_addr check_partial_addr check_ipv6_addr
    );

}


sub check_addr {
    my $addr = shift;
    return if(!defined($addr));
    $addr =~ s/\s+//;
    return $addr =~ /^$RE{net}{IPv4}$/;
#    return $addr =~ /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?\.?)((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){0,3}$/;
}

sub check_partial_addr {
  my $addr = shift;
  return if(!defined($addr));
  $addr =~ s/\s+//;
  
  if($addr =~ /^([0-9\.]+\.)$/o or $addr =~ /^(\.[0-9\.]+)$/o or
     $addr =~ /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/o) {
    return 1;
  }
}

#N.B. must be implemented
sub check_ipv6_addr {
    die "Not implemented";
}

my @INET_PREFIXES;
my %INET_NETMASK;


sub ip2int { return unpack( 'N', pack( 'C4', split( /\./, $_[0] ) ) ) }

sub int2ip { return join ".", unpack( "CCCC", pack( "N", $_[0] ) ); }

sub netmask_prefix2range {
    my $network = shift || croak "Missing network parameter";
    my $prefix = shift;
    defined($prefix) || croak "Missing prefix parameter";

    ( $prefix >= 0 || $prefix <= 32 ) or
        croak "Invalid subnet prefix";

    my $network_i   = Manoc::Utils::ip2int($network);
    my $netmask_i   = $prefix ? ~( ( 1 << ( 32 - $prefix ) ) - 1 ) : 0;
    my $from_addr_i = $network_i & $netmask_i;
    my $to_addr_i   = $from_addr_i + ~$netmask_i;

    return ( $from_addr_i, $to_addr_i, $network_i, $netmask_i );
}

sub prefix2netmask_i {
    @_ == 1 || croak "Missing prefix parameter";
    my $prefix = shift;
    ( $prefix >= 0 || $prefix <= 32 ) or
        croak "Invalid subnet prefix";

    return $prefix ? ~( ( 1 << ( 32 - $prefix ) ) - 1 ) : 0;
}

sub prefix2netmask {
    @_ == 1 || croak "Missing prefix parameter";
    my $prefix = shift;
    ( $prefix >= 0 || $prefix <= 32 ) or
        croak "Invalid subnet prefix";

    return $INET_PREFIXES[$prefix];
}

sub prefix2wildcard {
    @_ == 1 || croak "Missing prefix parameter";
    my $prefix = shift;
    ( $prefix >= 0 || $prefix <= 32 ) or
        croak "Invalid subnet prefix";

    return int2ip( $prefix ? ( ( 1 << ( 32 - $prefix ) ) - 1 ) : 0xFFFFFFFF );
}

sub netmask2prefix {
    my $netmask = shift || croak "Missing netmask parameter";

    return $INET_NETMASK{$netmask};
}

sub padded_ipaddr {
    my $addr = shift;
    defined($addr) or return;
    $addr =~ s/(^\.|\.$)//;
    $addr ne "" and join('.', map { sprintf('%03d', $_) } split( /\./, $addr ));
}

sub unpadded_ipaddr {
    my $addr = shift;
    join('.', map { sprintf('%d', $_) } split( /\./, $addr ))
}

BEGIN {
 
    $INET_PREFIXES[0] = '0.0.0.0';
    $INET_NETMASK{'0.0.0.0'} = 0;

    foreach my $i ( 1 .. 32 ) {
        my $netmask_i = ~( ( 1 << ( 32 - $i ) ) - 1 );

        $INET_PREFIXES[$i] = int2ip($netmask_i);
        $INET_NETMASK{ int2ip($netmask_i) } = $i;
    }
};


1;
