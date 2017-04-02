#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest;

init_manoctest;

my $mech = get_mech();
my $schema = ManocTest::Schema->get_schema();

mech_login;

# visit list starting from hwasset/device 
$mech->get_ok( '/hwasset/devices' );
$mech->title_is('Manoc - Device hardware');

like( $mech->find_link(  text =>'Add' )->url, qr|/hwasset/create_device$|, "Add link points to create");

$mech->get_ok('/hwasset/create_device');
$mech->title_is('Manoc - Create device hardware');
$mech->submit_form_ok({
    form_id => 'form-hwasset',
    fields => {
        'form-hwasset.vendor'         => 'Cisco',
        'form-hwasset.serial'         => 'FDO00001',
        'form-hwasset.model'          => 'ShinySwitch',
        # warehouse
        'form-hwasset.location'       => 'w',
    }
}, "Create device");
$mech->title_is('Manoc - Hardware Asset D000001', "Device page after redirect");

$mech->get_ok('/hwasset/1');
$mech->title_is('Manoc - Hardware Asset D000001', "Device page visiting URL");
$mech->get_ok( '/hwasset/devices', "Device list" );


done_testing();
