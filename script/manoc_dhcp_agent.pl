#!/usr/bin/perl -w

use strict;
use warnings;

use LWP::UserAgent;
use YAML::Syck;
use URI::Escape;

use Date::Parse;
use Data::Dumper;
use HTTP::Cookies;
#----------------------------------------------------------------------#
# Constants
#----------------------------------------------------------------------#

my $MANOC_URL   = "https://manoc/wapi";
my $SERVER_ID   = "dhcpserver";
my $CONF_FILE   = "/etc/dhcpd.conf";
my $LEASES_FILE = "/var/lib/dhcpd/dhcpd.leases";



my $LEASE_RE = qr/
  \s*lease\s((?:\d{1,3}\.){3}\d{1,3})\s*{
  \s*starts\s+\d\s+(\d{4}\/\d{2}\/\d{2}\s\d{2}:\d{2}:\d{2})\s*;
  \s*ends\s+\d\s+(\d{4}\/\d{2}\/\d{2}\s\d{2}:\d{2}:\d{2})\s*;
  (?:\s*tstp\s+\d\s+(\d{4}\/\d{2}\/\d{2}\s\d{2}:\d{2}:\d{2})\s*;)?
  (?:\s*tsfp\s+\d\s+(\d{4}\/\d{2}\/\d{2}\s\d{2}:\d{2}:\d{2})\s*;)?
  (?:\s*atsfp\s+\d\s+(\d{4}\/\d{2}\/\d{2}\s\d{2}:\d{2}:\d{2})\s*;)?
  (?:\s*cltt\s+\d\s+(\d{4}\/\d{2}\/\d{2}\s\d{2}:\d{2}:\d{2})\s*;)?    
  (?:\s*binding\ state\s+(\w+)\s*;)?
  (?:\s*next\ binding\ state\s+(\w+)\s*;)?
  \s*hardware\ \w+\s([^;]+)\s*;
  (?:\s*uid\s+"(.*)"\s*;)?
  (?:\s*set\s+remote-handle\s+=\s+%(\d+)\s*;)?
  (?:\s*client-hostname\s+"(.*)"\s*;)?
  \s*}\s*/mx;

my $RESERVATION_RE = qr/
  \s*host\s+([[:alnum:]-]+)\s*{
  \s*hardware\ ethernet
  \s+((?:[[:xdigit:]]{2}:){5}[[:xdigit:]]{2})\s*;
  \s*fixed-address\s+((?:\d{1,3}\.){3}\d{1,3})\s*;
  \s*option\ host-name\s+ "(\S+)";
  \s*}\s*/mx;

my $INCLUDE_RE = qr/\s*include\s+"([^"]+)"\s*;/;

#----------------------------------------------------------------------#
# Global variables
#----------------------------------------------------------------------#

my $User_agent;

#----------------------------------------------------------------------#

sub send_to_manoc {
    my $type = shift;
    my $data = shift;
    
    my $server_safe = uri_escape($SERVER_ID);

    my $url= $MANOC_URL;
    if ($type eq 'leases') {
	$url .= '/dhcp_leases';
    } elsif ($type eq 'reservations') {
	$url .= '/dhcp_reservations';
    } else {
	die "Unknown type $type";
    }

    $url .= "?server=$server_safe";

    my $req = HTTP::Request->new(POST => $url);
    $req->content_type('text/plain');
    
    $req->content(YAML::Syck::Dump(@$data));

    #basic authentication required
    $User_agent->credentials(
  	'manoc:443',
  	'<username>',
  	'<username>' => '<password>'
    );
    
    $User_agent->cookie_jar(HTTP::Cookies->new( 
        file => './.manoc_cookies.txt', 
        autosave => 1 ));


    my $res  = $User_agent->request($req);

    

    ### success: $res->is_success
    ### content: $res->content
  
    #unless($res->is_success){
    # print $res->content,"\n";
    #}

    return $res->is_success;
}

#----------------------------------------------------------------------#

sub parse_leases {
    my $self = shift;
    my @leases;
    my $file_data;
    my $hndl;

    return unless -e $LEASES_FILE;

    ### read config file: $LEASES_FILE
    $file_data = '';
    open($hndl, '<', $LEASES_FILE) or die $!;
    while (<$hndl>) {
	s/^([^#]*).*$/$1/;
	$file_data .= $_;
    }   
    close $hndl;

    ### search lease definitions
    while (1) {
	$file_data =~ m/$LEASE_RE/mxgo or last;
	push @leases, {
		       ipaddr   => $1,
		       start    => str2time($2, 'UTC'),
		       end      => str2time($3, 'UTC'), 
		       status   => $8,
		       macaddr  => lc($10),
		       hostname => $13 || '' 
		      };
    }
 
    return \@leases;
}

sub do_leases {
    my $leases = parse_leases;
    send_to_manoc('leases', $leases) or
      die "Error sending leases";

}

#----------------------------------------------------------------------#

sub parse_reservations {

    my @files_to_parse = ( $CONF_FILE );
    my @hosts;

    while ( @files_to_parse ) {

	my $filename = shift @files_to_parse;

	### read config file: $filename
	my $conf = '';
	open(my $hndl, '<', $filename) or die $!;
	while (<$hndl>) {
	    s/^([^\#]*).*$/$1/o;
	    $conf .= $_;
	}   
	close $hndl;

	### Parsing configuration...
	PARSE: while (1) {
	    if ( $conf =~ m/^$RESERVATION_RE/mxgoc ) {
		push @hosts, { 
			      name => $1, 
			      macaddr => lc($2), 
			      ipaddr => $3, 
			      hostname => $4 
			     };
		next PARSE;
	    }
	    if ( $conf =~ m/$INCLUDE_RE/mxgoc ) {
		my $file = $1;
	        ### include file: $file
		push @files_to_parse, $file;
		next PARSE;
	    }
	    last PARSE;
	}
    }
    return \@hosts;
}

sub do_reservations {
    my $r = parse_reservations;
    send_to_manoc('reservations', $r) or
      die "Error sending reservations";

}

#----------------------------------------------------------------------#

sub main {

    # init UA
    $User_agent = LWP::UserAgent->new;

    do_leases;
    do_reservations;

    exit 0;
}

main;
