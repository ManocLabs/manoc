#!/usr/bin/perl 

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Manoc::Support;
package Manoc::IPFill;

use LWP::UserAgent;
use URI::Escape;

use Data::Dumper;
use HTTP::Cookies;

use Moose;

extends 'Manoc::App';
with 'MooseX::Getopt::Dashes';

has 'manoc_url' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    #default => ""
);

has 'ip_file' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    #default => ""
);

has 'user_agent' => (
    traits     => ['NoGetopt'],
    is         => 'ro',
    required   => 0,
    lazy_build => 1,
);

sub _build_user_agent { return LWP::UserAgent->new ;}
#----------------------------------------------------------------------#

sub send_to_manoc {
    my $self = shift;
    my $data = shift; 
    my $url= $self->manoc_url.'/ipinfo';

    #basic authentication required
    $self->user_agent->credentials(
  	'manoc.policlinico.org:443',
  	'agents',
  	'agents' => 'agent1n0',
    );
    
    $self->user_agent->cookie_jar(HTTP::Cookies->new(
     file => './.manoc_cookies.txt',
     autosave => 1 ));

    foreach my $i (@{$data}){
      $url  = $self->manoc_url.'/ipinfo';
      $url .= "?ipaddr=".$i->{ipaddr};
      foreach my $c (keys %{$i}){
       $c eq 'ipaddr' and next;
       $i->{$c} ne '' and $url .= "\&$c=".uri_escape($i->{$c});
      }

      my $req  = HTTP::Request->new(GET => $url);
      my $res  = $self->user_agent->request($req);

      if($res->is_success){
        print "Request OK: $url\n";
      }
      else{
        print $res->content,"\n";
        die "Failure for request: $url\n";
      }
    }
    return 1;
}

#----------------------------------------------------------------------#

sub parse_ipinfo {
    my $self = shift;
    my @infos;
    my $file_data;
    my $hndl;

    return unless -e $self->ip_file;

    $file_data = '';
    open($hndl, '<', $self->ip_file) or die $!;
    while (<$hndl>) {
	s/^([^#]*).*$/$1/;
	$file_data .= $_;
    }   
    close $hndl;

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


sub run {
  my $self = shift;

  my $infos = $self->parse_ipinfo;
  $self->send_to_manoc($infos) or
      die "Error sending IP informations";
}


no Moose;

package main;

my $app = Manoc::IPFill->new_with_options();
$app->run;

