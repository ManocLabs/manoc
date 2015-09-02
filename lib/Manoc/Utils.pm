# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::Utils;

use strict;
use warnings;

BEGIN {
    use Exporter 'import';
    our @EXPORT_OK = qw/clean_string 
			str2seconds print_timestamp
			check_mac_addr/;
};

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
#                    S t r i n g    F u n c t i o n s                  #
#                                                                      #
########################################################################


sub check_mac_addr {
    my $addr = shift;
    return $addr =~ /^$RE{net}{MAC}$/;
}

sub clean_string {
    my $s = shift;
    return '' unless defined $s;
    $s =~ s/^\s+//o;
    $s =~ s/\s+$//o;
    return lc($s);
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
    my ($tarname, $basedir, $filelist_ref )  = @_;
    my $command = "tar";
    
    #check the existence of tar command
    #running tar --version 
    `$command --version 2>&1`;
    if($? == 0){
	#use system tar
	#remove leading path from filelist to avoid creating tar with 
	#file that have complete path e.g. /tmp/device.yaml
	my @sanitized;
	foreach my $file (@$filelist_ref) {
	    $file =~ s/^$basedir\/?//o;
	    push @sanitized, $file;
	}
	`$command -zcf $tarname -C $basedir/ @sanitized 2>&1`;
	return $?;
    } else {
	#use Archive::Tar    
	my $tar = Archive::Tar->new;
	my @obj_list = $tar->add_files( @$filelist_ref );
	
	#remove prefix
	foreach my $o (@obj_list){
	    $o->prefix('');
	}
	return $tar->write( $tarname, 1  );
    }    
  }


########################################################################
#                                                                      #
#           D a t e   &   t i m e   F u n c t i o n s                  #
#                                                                      #
########################################################################

sub str2seconds {
    my ($str, $unit) = @_;

    croak "empty input string" unless defined $str;

    my ( $num, $unit2 ) = $str =~ m/^([+-]?\d+)([smhdwMy]?)$/;
    if ($unit && $unit2) {
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


sub print_timestamp {
    my $timestamp = shift @_;
    defined($timestamp) || croak "Missing timestamp";
    my @timestamp = localtime($timestamp);
    return strftime( "%d/%m/%Y %H:%M:%S", @timestamp );
}

1;
