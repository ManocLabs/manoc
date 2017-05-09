package App::Manoc::Utils;
#ABSTRACT: Miscellaneous support functions
use strict;
use warnings;

##VERSION

BEGIN {
    use Exporter 'import';
    our @EXPORT_OK = qw/clean_string
        check_mac_addr/;
}

use Regexp::Common qw/net/;

use Carp;
use Archive::Tar;

########################################################################
#                                                                      #
#                    S t r i n g    F u n c t i o n s                  #
#                                                                      #
########################################################################

=function check_mac_addr($addr)

Return 1 if C<$addr> is a valid MAC address.

=cut

sub check_mac_addr {
    my $addr = shift;
    return $addr =~ /^$RE{net}{MAC}$/;
}

=function clean_string($s)

Return C<$s> trimmed and lowercase.

=cut

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

=function decode_bitset($bits, \@names)

Given a string representation of a bitlist and a list of names return
the names corresponding to 1 bits.

 decode_bitset('0110', ['one', 'two', 'three', 'four' ])

gives C<('two', 'three')>.


=cut

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

=function tar($filename, $basedir, \@files)

Create a tar file called c<$filename> with files in C<@files> storing
their paths relatively to C<$basedir>.

Use the C<tar> command if present, otherwise Archive::Tar.

=cut

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
