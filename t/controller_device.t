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

# visit (empty) device  list
$mech->get_ok( '/device' );
$mech->title_is( 'Manoc - Devices' );

like( $mech->find_link(  text =>'Add device' )->url, qr|/device/create$|, "Add link points to create");

# continue testing even if Add link is broken
$mech->get_ok('/device/create', "Create device page");
$mech->submit_form_ok(
    {
        form_id   => 'form-device',
        fields    => {
        },
    },
    "Submit uncomplete form",
);
$mech->text_contains( 'Address field is required' );

# try with a correct form
$mech->submit_form_ok(
    {
        form_id => 'form-device',
        fields  => {
            'form-device.name'        => 'Device 01',
            'form-device.mng_address' => '10.0.0.1',
        },
    },
    "Create device",
);
like ( $mech->base(), qr|/device$|, "Redirected to device list");

$mech->text_contains('Device 01', "New device in the list");
$mech->follow_link_ok({ text => 'Device 01'}, "View device page");
$mech->title_is('Manoc - Device Device 01');

#ok($mech->find_link(text => 'Add netwalker'), "Add server link");

$mech->follow_link_ok({text => 'Delete'}, "Follow delete link");
# first form is search box
$mech->submit_form_ok({ form_number => 2 }, "Submit delete form");

$mech->content_lacks('Device 01', "Device no longer in the list");

# hwasset and decommission test

my $rack = $schema->resultset("Rack")->create({
    name => 'R01',
    floor => 1,
    room => '00',
    building => { name => 'B01', description => 'Test building' },
});
my $hwasset = $schema->resultset("HWAsset")->create(
        {
            type       => Manoc::DB::Result::HWAsset->TYPE_DEVICE,
            vendor     => 'IQ',
            model      => 'MegaPort 48',
            serial     => 'TestHW01',
            inventory  => 'Inv001'
        });
$hwasset->discard_changes;

$mech->get('/device/create');
$mech->submit_form_ok(
    {
        form_id => 'form-device',
        fields  => {
            'form-device.name'        => 'Device 02',
            'form-device.mng_address' => '10.0.0.1',
            'form-device.hwasset'     => $hwasset->id,
            'form-device.rack'        => $rack->id,
        },
    },
    "Create device",
);
like( $mech->base(), qr|/device$|, "Redirected to device list" );

$hwasset->discard_changes;
ok($hwasset->is_in_rack, "HWAsset is in rack");
my $device = $schema->resultset('Device')->find({ name => 'Device 02' });
ok($device->hwasset, "HWAsset is associated to Device");

$mech->follow_link_ok({ text => 'Device 02' }, "View device page");
$mech->text_contains('Inv001', "HWasset is displayed in list");


$mech->follow_link_ok({text => 'Decommission'}, "Follow decommission link");
# first form is search box
$mech->submit_form_ok(
    {
        form_number => 2,
        fields => {
            'form-decommission.asset_action' => 'DECOMMISSION'
        },
    },
    "Submit decommission form"
);
like ( $mech->base(), qr|/device$|, "Redirected to device list");


$device->discard_changes;
$hwasset->discard_changes;
ok($device->decommissioned, "Device is decommissioned");
ok($hwasset->is_decommissioned, "Asset is decommissioned");
ok(!defined($device->hwasset), "HWAsset is no more associated to Device");


done_testing();
