#!/usr/bin/perl
# -*- cperl -*-
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Manoc::Support;

package Manoc::CheckDevConfig;
use Moose;
use Manoc::Logger;
use Manoc::IpAddress;

use Manoc::Utils qw(str2seconds print_timestamp);
use Data::Dumper;

use Socket;


use Data::Dumper;

extends 'Manoc::App';

has 'help' => (
    is => 'rw', 
    isa => 'Bool', 
    required => 0, 
   );

has 'numeric' => (
    is => 'rw', 
    isa => 'Bool', 
    required => 0, 
   );

has 'device' => (
    is => 'ro', 
    isa => 'Str', 
    required => 0, 
   );

has 'check_lines' => (
                 traits   => ['NoGetopt'],
                 is       => 'ro',
                 isa      => 'ArrayRef',
                 lazy_build  => 1,
               );


sub _build_check_lines {
  my ($self) = @_;
  my @lines;
  my $config = $self->config->{'CheckConfig'}->{'check'};

      if(defined($config)){
        if ( ref($config) eq 'ARRAY' ) {
            @lines = @$config;
        }
        else {
            push @lines, $config;
        }
      }
  return \@lines;
}


sub run {
    my ($self) = @_;
    my @devices;
    my @lines = @{$self->check_lines};
    my $line;
    my $result = {};
    

    foreach $line (@lines) {
      $result->{$line} = [];
    }
    #prepare the device list to visit
    if ($self->device) {
        push @devices, Manoc::Utils::padded_ipaddr($self->device);
    } else {
        @devices = $self->schema->resultset('Device')->get_column('id')->all;
    }

    foreach my $device (@devices) {
      my $device_id = Manoc::Utils::unpadded_ipaddr($device);
      my $dev_conf = $self->schema->resultset('DeviceConfig')->find( $device );
      unless($dev_conf){
	$self->log->error("Device config of ".$device_id." not found!");
	next;	
      }
      #retrieve config
      my $config = $dev_conf->config;
      #check config lines included in manoc.conf
      foreach $line (@lines) {
	if($config !~ m/$line/i ){
	  $self->log->debug("Device configuration of ".$device_id." dosen't containt the line $line");
	  push @{$result->{$line}}, $device_id;
	}
	else {
	}
      }
    }
    if($self->numeric){
      print "Statistics:\n";
      foreach my $t (keys %{$result}) {
	print "\t   $t: ".scalar(@{$result->{$t}})."\n";
      }
    }
    else {
    print Dumper($result);
  }
  }

no Moose;

package main;

my $app = Manoc::CheckDevConfig->new_with_options();
$app->run();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
