#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib "t/lib";


use ManocTest::Schema;


my $schema = ManocTest::Schema->connect();
ok($schema, "Create schema");


# prepare some ipblocks to be used later
my $block01 = $schema->resultset("IPBlock")->create({
    from_addr => App::Manoc::IPAddress::IPv4->new('192.168.1.0'),
    to_addr   => App::Manoc::IPAddress::IPv4->new('192.168.1.100'),
    name      => 'Block01'
});
ok($block01, "Created block 192.168.1.10-100");
cmp_ok($block01->from_addr->padded, 'eq', '192.168.001.000',
       "From address looks like a IPV4 object");
cmp_ok($block01->to_addr->padded, 'eq', '192.168.001.100',
       "To address looks like a IPV4 object");


# prepare some ipblocks to be used later
my $block02 = $schema->resultset("IPBlock")->create({
    from_addr => App::Manoc::IPAddress::IPv4->new('192.168.1.50'),
    to_addr   => App::Manoc::IPAddress::IPv4->new('192.168.1.100'),
    name      => 'Block02'
});
ok($block02, "Created block 192.168.2.0-100");


my $net01 = $schema->resultset("IPNetwork")->create({
    address => App::Manoc::IPAddress::IPv4->new('192.168.1.0'),
    prefix  => '24',
    name    => 'Net01'
});
ok($net01, "Create Net01 192.168.1.0/24");

cmp_ok($net01->broadcast->padded, 'eq', '192.168.001.255',
   "Check broadcast address in new network");

my $net02 = $schema->resultset("IPNetwork")->create({
    network => App::Manoc::IPAddress::IPv4Network->new('192.168.1.0', 25),
    name    => 'Net02',
});
ok ($net02, "Created 192.168.1.0/25 using network object");

cmp_ok($net02->parent->id, '==', $net01->id, "192.168.1.0/25 parent is 192.168.1.0/24");

my $net03 = $schema->resultset("IPNetwork")->create({
    network => App::Manoc::IPAddress::IPv4Network->new('192.168.1.0', 26),
    name    => 'Net03',
});
ok ($net02, "Created 192.168.1.0/26 using network object");

cmp_ok($net03->supernets->count, '==', 2, "192.168.1.0/26 has 2 supernets");
cmp_ok(
    $net03->first_supernet->id, '==', $net02->id,
    "192.168.1.0/26 first supernet is 192.168.1.0/25"
);

my $net02b = $schema->resultset("IPNetwork")->create({
    network => App::Manoc::IPAddress::IPv4Network->new('192.168.1.128', 25),
    name    => 'Net02b',
});

ok ($net02b, "Created 192.168.1.128/25");

cmp_ok($net01->children->count, '==', 2, "192.168.1.0/24 has now 2 childrens");
cmp_ok($net01->subnets->count, '==', 3, "192.168.1.0/24 has now 3 subnets");

cmp_ok($net01->ipblock_entries->count, '==', 2, "192.168.1.0/24 has 2 ipblocks");
cmp_ok($block01->container_network->id, '==', $net01->id,
       "192.168.1.0-100 container is 192.168.1.0/24");

cmp_ok($block01->contained_networks->count, '==', 1,
       "192.168.1.0-100 contains 1 network");





done_testing();
