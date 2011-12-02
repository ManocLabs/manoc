#!/usr/bin/perl
# -*- cperl -*-
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Manoc::Support;

package Manoc::TestIpaddr;
use Moose;
use Manoc::Logger;
use Manoc::Ipaddr;

use Data::Dumper;

extends 'Manoc::App';


sub run {
    my ($self) = @_;
    my $timestamp = time;

    my $ipaddr = Manoc::Ipaddr->new({address=> "172.3.4.5"});
    
     my @rs = $self->schema->resultset('Arp')->search({ipaddr=>$ipaddr});

      unless(scalar(@rs)){
         $self->schema->resultset('Arp')->create(
                             {
                              ipaddr    => Manoc::Ipaddr->new({address=>"172.3.4.5"}),
                              macaddr   => "00:01:02:03:04:05",
                              firstseen => $timestamp,
                              lastseen  => $timestamp,
                              vlan      => 1,
                              archived  => 0
                             }
                                                );
         @rs = $self->schema->resultset('Arp')->search({ipaddr =>Manoc::Ipaddr->new({address=>"172.3.4.5"})});
        
     }
     my $rs = shift @rs;
 print $rs->get_column('ipaddr'),"\n";
   


     $rs->delete;
    exit 0;
}






no Moose;

package main;

my $app = Manoc::TestIpaddr->new_with_options();
$app->run();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
