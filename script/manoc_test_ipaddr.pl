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
use Manoc::IpAddress;
use Manoc::IpAddress::Ipv4;

use Data::Dumper;

extends 'Manoc::App';


sub run {
    my ($self) = @_;
    my $timestamp = time;

  #  my $ipaddr = Manoc::IpAddress::Ipv4->new({address=>"72.3.45.25"});
    
    my $ipaddr = Manoc::IpAddress::Ipv4->new({ padded=>"072.003.045.025"});

#     $self->schema->resultset('Arp')->update_or_create(
#         {
#             ipaddr    => Manoc::Ipv4->new( { addr => "172.3.4.5" } ),
#             macaddr   => "00:01:02:03:04:05",
#             firstseen => $timestamp,
#             lastseen  => $timestamp,
#             vlan      => 1,
#             archived  => 0
#         }
#     );

#     $self->schema->resultset('Arp')->update_or_create(
#         {
#             ipaddr    => Manoc::Ipv4->new( { addr => "172.1.2.3" } ),
#             macaddr   => "00:01:02:03:04:05",
#             firstseen => $timestamp,
#             lastseen  => $timestamp,
#             vlan      => 1,
#             archived  => 0
#         }
#     );

     $self->schema->resultset('IPRange')->update_or_create(
         {
             name      => 'subnet_di_test2',
             network   => Manoc::IpAddress->new( "172.3.4.0"  ),
             netmask   => Manoc::IpAddress->new( "255.255.255.128"  ),
             from_addr => Manoc::IpAddress->new(  "172.3.4.0"  ),
             to_addr   => Manoc::IpAddress->new(  "172.3.4.127"  ),
             parent    => 'subnet_di_test_noaton',
             vlan_id   => 1,
         }
     );
     $self->schema->resultset('IPRange')->update_or_create(
         {
             name      => 'subnet_di_test3',
             network   => Manoc::IpAddress->new( "172.3.4.128"  ),
             netmask   => Manoc::IpAddress->new( "255.255.255.128"  ),
             from_addr => Manoc::IpAddress->new( "172.3.4.128"  ),
             to_addr   => Manoc::IpAddress->new( "172.3.4.255"  ),
             parent    => 'subnet_di_test_noaton',
             vlan_id   => 1,
         }
     );


    # my $ranges =  $self->schema->resultset('IPRange')->search(
    #     [
    #         {
    #             'from_addr' => { '<=' => $ipaddr },
    #             'to_addr'   => { '>=' => $ipaddr },
    #         }
    #     ],
    #     { order_by => 'from_addr DESC, to_addr' }
    # )->single;


    # my $ranges = $self->schema->resultset('IPRange')->search(
    #     {
    #         -and => [
    #             'from_addr' => Manoc::Ipv4->new( { addr => "172.3.4.0" } ),
    #             'to_addr'   => Manoc::Ipv4->new( { addr => "172.3.4.254" } ),
    #         ]
    #     }
    # )->single;

    # print $ranges->name, "\n";

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
