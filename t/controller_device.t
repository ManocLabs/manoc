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
like ( $mech->base(), qr|/device$|, "Redirected to device ist") or $mech->dump_text;

$mech->text_contains('Device 01', "New device in the list");
$mech->follow_link_ok({ text => 'Device 01'}, "View device page");
$mech->title_is('Manoc - Device Device 01');

#ok($mech->find_link(text => 'Add netwalker'), "Add server link");

$mech->follow_link_ok({text => 'Delete'}, "Follow delete link");
# first form is search box
$mech->submit_form_ok({ form_number => 2 }, "Submit delete form");

$mech->content_lacks('Device 01', "Device no longer in the list");

done_testing();
