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
use Manoc::Ipv4;

use Data::Dumper;

extends 'Manoc::App';


sub run {
    my ($self) = @_;
    my $timestamp = time;

    my $ipaddr = Manoc::Ipv4->new({addr=> "172.3.4.5"});
    

#          $self->schema->resultset('Arp')->create(
#                              {
#                               ipaddr    => Manoc::Ipv4->new({addr=>"172.3.4.5"}),
#                               macaddr   => "00:01:02:03:04:05",
#                               firstseen => $timestamp,
#                               lastseen  => $timestamp,
#                               vlan      => 1,
#                               archived  => 0
#                              }
#                                                 );
#     @rs = $self->schema->resultset('Arp')->search({ipaddr =>Manoc::Ipv4->new({addr=>"172.3.4.5"})});

      
     $self->schema->resultset('IPRange')->create(
                               {
                                name      => 'subnet_di_test',
                                network   => Manoc::Ipv4->new({addr=>"11.11.11.0"}),
                                netmask   => Manoc::Ipv4->new({addr=>"255.255.255.0"}),
                                from_addr => Manoc::Ipv4->new({addr=>"11.11.11.0"}),
                                to_addr   => Manoc::Ipv4->new({addr=>"11.11.11.254"}),
                                parent    => 'CED',
                                vlan_id  => 1,
                               }
                                                 );

      
     my @r = $self->schema->resultset('IPRange')->search(
         [
          {
           'netmask' => { '<=' =>  Manoc::Ipv4->new({addr=>"11.11.11.3"})},
           'to_addr'   => { '>=' =>  Manoc::Ipv4->new({addr=>"11.11.11.3"})},             
         }
                                                           ],
         { order_by => 'from_addr DESC, to_addr' }
         );
     my $rs = shift @r;
 print $rs->get_column('name'),"\n";
   


     #$rs->delete;
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
