# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::Utils;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
    clean_string print_timestamp
    ip2int int2ip str2seconds
    netmask_prefix2range netmask2prefix
    padded_ipaddr
    prefix2wildcard check_addr check_mac_addr check_ipv6_addr
    check_backref set_backref deny_access
);

use POSIX qw(strftime);

use FindBin;
use File::Spec;

use Regexp::Common qw/net/;

use Manoc::DB;
use Carp;
use Archive::Tar;

########################################################################

# get manoc home and cache it
my $Manoc_Home;

sub set_manoc_home {
    my $home = shift || croak "Missing path";

    # manoc home cannot be changed!
    if ( defined $Manoc_Home ) {
        carp "Manoc home already set";
        return;
    }

    $Manoc_Home = $home;
}

sub get_manoc_home {
    return $Manoc_Home if defined $Manoc_Home;

    $Manoc_Home = $ENV{MANOC_HOME};
    $Manoc_Home ||= File::Spec->catfile( $FindBin::Bin, File::Spec->updir() );
    return $Manoc_Home;
}

########################################################################
#                                                                      #
#                   S t r i n g   F u n c t i o n s                    #
#                                                                      #
########################################################################

sub clean_string {
    my $s = shift;
    return '' unless defined $s;
    $s =~ s/^\s+//o;
    $s =~ s/\s+$//o;
    return lc($s);
}

sub check_addr {
    my $addr = shift;
    return if(!defined($addr));
    $addr =~ s/\s+//;
    return $addr =~ /^$RE{net}{IPv4}$/;
#    return $addr =~ /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?\.?)((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){0,3}$/;
}

sub check_mac_addr {
    my $addr = shift;
    return $addr =~ /^$RE{net}{MAC}$/;
}

#N.B. must be implemented
sub check_ipv6_addr {
  return undef;
}

########################################################################
#                                                                      #
#           D a t e   &   t i m e   F u n c t i o n s                  #
#                                                                      #
########################################################################

sub print_timestamp {
    my $timestamp = shift @_;
    defined($timestamp) || croak "Missing timestamp";
    my @timestamp = localtime($timestamp);
    return strftime( "%d/%m/%Y %H:%M:%S", @timestamp );
}

sub str2seconds {
    my ($str) = @_;

    return unless defined $str;

    return $str if $str =~ m/^[-+]?\d+$/;

    my %map = (
        's' => 1,
        'm' => 60,
        'h' => 3600,
        'd' => 86400,
        'w' => 604800,
        'M' => 2592000,
        'y' => 31536000
    );

    my ( $num, $m ) = $str =~ m/^([+-]?\d+)([smhdwMy])$/;

    ( defined($num) && defined($m) ) or
        carp "couldn't parse '$str'. Possible invalid syntax";

    return $num * $map{$m};
}

########################################################################
#                                                                      #
#                   I P A d d r e s s   F u n c t i o n s              #
#                                                                      #
########################################################################

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
    join('.', map { sprintf('%03d', $_) } split( /\./, $addr ))
}

sub unpadded_ipaddr {
    my $addr = shift;
    join('.', map { sprintf('%d', $_) } split( /\./, $addr ))
}

BEGIN {
    my $netmask_i;

    $INET_PREFIXES[0] = '0.0.0.0';
    $INET_NETMASK{'0.0.0.0'} = 0;

    foreach my $i ( 1 .. 32 ) {
        $netmask_i = ~( ( 1 << ( 32 - $i ) ) - 1 );

        $INET_PREFIXES[$i] = int2ip($netmask_i);
        $INET_NETMASK{ int2ip($netmask_i) } = $i;
    }
  }

########################################################################
#                                                                      #
#                     S e t    F u n c t i o n s                       #
#                                                                      #
########################################################################

sub decode_bitset {
    my $bits  = shift;
    my $names = shift;

    my @result;

    my @bitlist = reverse split( //, $bits );
    my ( $n, $b );

    while ( @$names && @bitlist ) {
        $n = shift @$names;
        $b = shift @bitlist;

        $b or next;
        push @result, $n;
    }

    return @result;
}

########################################################################
#                                                                      #
#                   T a r   F u n c t i o n s                          #
#                                                                      #
########################################################################

sub tar {
    my ($config, $tarname, @filelist )  = @_;
    my $command = "tar";
    my $dir;
    #if tar isn't in path system
    if(defined $config){
      my $path = $config->{'path_to_tar'};
      $path and $path =~ s/\/$//;
      $command = $path."/tar" if(defined $path and $path ne '');
      $dir = $config->{'directory'};
      $dir ||= "/tmp";
      $dir and $dir =~ s/\/$//;
    }
    #check the existence of tar command
    #running tar --version 
    `$command --version 2>&1`;
    if($? == 0){
      #use system tar
      #remove leading path from filelist to avoid creating tar with 
      #file that have complete path e.g. /tmp/device.yaml
       my @sanitized;
       foreach my $file (@filelist){
	 $file =~ s/^\/(\w+\/)+//;
	 push @sanitized, $file;
       }
      `$command -zcf $tarname -C $dir/ @sanitized 2>&1`;
      return $?;
    }
    else {
      #use Archive::Tar    
      my $tar = Archive::Tar->new;
      my @obj_list = $tar->add_files( @filelist );
      #remove /tmp prefix
      foreach my $o (@obj_list){
	$o->prefix('');
      }
      return $tar->write( $tarname, 1  );
    }
    
  }


1;
