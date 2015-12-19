#!/usr/bin/perl -w

use strict;
use warnings;

use LWP::UserAgent;
use URI::Escape;
use IO::Handle;
use HTTP::Cookies;
#----------------------------------------------------------------------#
# Constants
#----------------------------------------------------------------------#

my $MANOC_URL = "http://manoc2/wapi/winlogon";

my @FIELD_NAMES = qw(
    EventLogType
    Criticality
    SourceName
    SnareEventCounter
    DateTime
    EventID
    SourceName
    UserName
    SIDType
    EventLogType
    ComputerName
    Category
    DataString
    ExpandedString
);

#----------------------------------------------------------------------#
# Global variables
#----------------------------------------------------------------------#

my $User_agent;

#----------------------------------------------------------------------#

sub parse_msg {
    my $msg = shift;
    my %event;

    my @fields;
    @fields = split( /\t/, $msg );
    for ( my $i = 0; $i < @FIELD_NAMES; $i++ ) {
        $event{ $FIELD_NAMES[$i] } = $fields[$i];
    }

    # parse expanded string
    @fields = split( /\s{2,}/, $event{ExpandedString} );
    my %details;
    foreach (@fields) {
        my @p = split /:\s*/, $_;
        $p[1] and $details{ $p[0] } = $p[1];
    }
    $event{data} = \%details;

    return \%event;
}

sub send_manoc_logon {
    my ( $user, $ipaddr ) = @_;

    my $user_safe = uri_escape($user);
    my $url       = "$MANOC_URL?user=$user_safe\&ipaddr=$ipaddr";

    my $req = HTTP::Request->new( GET => $url );

    my $res = $User_agent->request($req);
}

#----------------------------------------------------------------------#

sub main {

    # uncomment for debug
    # open STDERR, ">>/tmp/manocerr";

    # init UA
    $User_agent = LWP::UserAgent->new;
    $User_agent->credentials( '<host>:443', '<username>', '<username>' => '<password>' );

    $User_agent->cookie_jar(
        HTTP::Cookies->new(
            file     => './.manoc_cookies.txt',
            autosave => 1
        )
    );

    open my $fh, ">>/tmp/manoctest";
    $fh->autoflush(1);

    print $fh join( ",", @FIELD_NAMES ), "\n";

    while (1) {
        my $date = <>;
        defined($date) or last;
        chomp($date);

        my $host = <>;
        defined($host) or last;
        chomp($host);

        my $msg = <>;
        defined($msg) or last;
        chomp($msg);

        my $event = parse_msg($msg);

        if ( $event->{EventID} == 672 && $event->{EventLogType} eq 'Success Audit' ) {
            # Ticket granted
            send_manoc_logon( $event->{data}->{"User Name"},
                $event->{data}->{"Client Address"} );
        }

    }

    close $fh;
}

main;
1;
