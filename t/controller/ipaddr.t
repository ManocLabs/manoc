#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest;

init_manoctest;

my $mech   = get_mech();
my $schema = ManocTest::Schema->get_schema();

mech_login;

# prepare some info to be used later
my $ip1 = $schema->resultset("IPAddressInfo")->create(
    {
        ipaddr => App::Manoc::IPAddress::IPv4->new('192.168.1.1'),
    }
);
ok( $ip1, "Created ipaddrinfo 192.168.1.1" );


# visit (empty) ip info page list
$mech->get_ok('/ip/192.168.1.1');
$mech->title_is('Manoc - Info about 192.168.1.1');

done_testing();
