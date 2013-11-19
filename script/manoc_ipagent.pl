#!/usr/bin/perl 

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

my $MANOC_URL   = "https://manoc.policlinico.org/wapi";
my $IP_FILE     = "/opt/manoc_clients/indirizzi100.csv";

#----------------------------------------------------------------------#
# Global variables
#----------------------------------------------------------------------#

my $User_agent;

#----------------------------------------------------------------------#

sub send_to_manoc {
    my $data = shift;
    
    my $url= $MANOC_URL.'/ipinfo';

    #basic authentication required
    $User_agent->credentials(
  	'manoc.policlinico.org:443',
  	'agents',
  	'agents' => 'agent1n0',
    );
    
    $User_agent->cookie_jar(HTTP::Cookies->new(
     file => './.manoc_cookies.txt',
     autosave => 1 ));

    foreach my $i (@{$data}){
      $url  = $MANOC_URL.'/ipinfo';
      $url .= "?ipaddr=".$i->{ipaddr};
      foreach my $c (keys %{$i}){
       $c eq 'ipaddr' and next;
       $i->{$c} ne '' and $url .= "\&$c=".uri_escape($i->{$c});
      }

      my $req  = HTTP::Request->new(GET => $url);
      my $res  = $User_agent->request($req);

      if($res->is_success){
        print "Request OK: $url\n";
      }
      else{
        print $res->content,"\n";
        die "Failure for request: $url\n";
      }
    }
    ### success: $res->is_success
    ### content: $res->content
  
    #unless($res->is_success){
    # print $res->content,"\n";
    #}

    return 1;
}

#----------------------------------------------------------------------#

sub parse_ipinfo {
    my $self = shift;
    my @infos;
    my $file_data;
    my $hndl;

    return unless -e $IP_FILE;

    ### read config file: $LEASES_FILE
    $file_data = '';
    open($hndl, '<', $IP_FILE) or die $!;
    while (<$hndl>) {
	s/^([^#]*).*$/$1/;
	$file_data .= $_;
    }   
    close $hndl;

    ### search lease definitions
    while (1) {
	$file_data =~ m/([\d\.]+),(.*),(.*),(.*),(.*),(.*)/mxgo or last;
	push @infos, {
		       ipaddr   => $1,
		       descr    => $2,
		       assigned => $3, 
		       phone    => $4,
		       email    => $5,
		       notes    => $6 
		      };
    }
 
    return \@infos;
}

sub do_ipinfo {
    my $infos = parse_ipinfo;
    send_to_manoc($infos) or
      die "Error sending IP informations";

}

#----------------------------------------------------------------------#

sub main {

    # init UA
    $User_agent = LWP::UserAgent->new;

    do_ipinfo;

    exit 0;
}

main;
