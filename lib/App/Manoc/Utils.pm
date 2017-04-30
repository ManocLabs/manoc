# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package App::Manoc::Utils;

use strict;
use warnings;

BEGIN {
    use Exporter 'import';
    our @EXPORT_OK = qw/clean_string
        check_mac_addr/;
}

use FindBin;
use File::Spec;

use Regexp::Common qw/net/;

use App::Manoc::DB;
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
    my ( $tarname, $basedir, $filelist_ref ) = @_;
    my $command = "tar";

    #check the existence of tar command
    #running tar --version
    `$command --version 2>&1`;
    if ( $? == 0 ) {
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
    }
    else {
        #use Archive::Tar
        my $tar      = Archive::Tar->new;
        my @obj_list = $tar->add_files(@$filelist_ref);

        #remove prefix
        foreach my $o (@obj_list) {
            $o->prefix('');
        }
        return $tar->write( $tarname, 1 );
    }
}

1;
