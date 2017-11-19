#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest::Schema;

my $schema = ManocTest::Schema->connect();
ok( $schema, "Create schema" );

my $ip1 = $schema->resultset("IPAddressInfo")->create(
    {
        ipaddr => App::Manoc::IPAddress::IPv4->new('192.168.1.1'),
    }
);
ok( $ip1, "Created ipaddrinfo 192.168.1.1" );

done_testing();
