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

# visit list
$mech->get_ok( '/serverhw' );
$mech->title_is('Manoc - Server Hardware');

like( $mech->find_link(  text =>'Add' )->url, qr|/serverhw/create$|, "Add link points to create");

$mech->get_ok('/serverhw/create');
$mech->title_is('Manoc - Create server hardware');
$mech->submit_form_ok({
    form_id => 'form-serverhw',
    fields => {
        'form-serverhw.ram_memory'     => '16000',
        'form-serverhw.cpu_model'      => 'E1234',
        'form-serverhw.vendor'         => 'Moon',
        'form-serverhw.serial'         => 'moo001',
        'form-serverhw.model'          => 'ShinyBlade',
        # warehouse
        'form-serverhw.location'       => 'w',
    }
}, "Create serverhw");
$mech->title_is('Manoc - Server Hardware S000001', "Server page");

# add another asset just to complicate the scenario
$schema->resultset('HWAsset')->create({
    type       => Manoc::DB::Result::HWAsset->TYPE_DEVICE,
    vendor     => 'IQ',
    model      => 'MegaPort 24',
    serial     => 'Test04',
});

$mech->get_ok('/serverhw/create');
$mech->title_is('Manoc - Create server hardware');
$mech->submit_form_ok({
    form_id => 'form-serverhw',
    fields => {
        'form-serverhw.ram_memory'     => '16000',
        'form-serverhw.cpu_model'      => 'E1234',
        'form-serverhw.vendor'         => 'Moon',
        'form-serverhw.serial'         => 'moo002',
        'form-serverhw.model'          => 'ShinyBlade',
        # warehouse
        'form-serverhw.location'       => 'w',
    }
}, "Create another serverhw");
$mech->title_is('Manoc - Server Hardware S000003', "Server page");

$mech->get_ok( '/serverhw', "Server list" );
$mech->follow_link_ok({ text => 'S000003' }, 'Follow link from list');

$mech->follow_link_ok({ text => 'Edit' }, 'Follow edit link');
$mech->title_is('Manoc - Edit server hardware');
$mech->submit_form_ok({
    form_id => 'form-serverhw',
    fields => {
        'form-serverhw.ram_memory'     => '16000',
        'form-serverhw.cpu_model'      => 'E1234',
        'form-serverhw.vendor'         => 'Moon',
        'form-serverhw.serial'         => 'moo002',
        'form-serverhw.model'          => 'YServer',
        # warehouse
        'form-serverhw.location'       => 'w',
        'form-serverhw.storage1'       => '10',
        'form-serverhw.storage2'       => '20',

    }
}, "Edit serverhw");
$mech->title_is('Manoc - Server Hardware S000003', "Back to server page");
$mech->text_contains("YServer", "Server page contains new model name");

$mech->follow_link_ok({ text => 'Decommission' }, 'Follow decommision link');
$mech->submit_form_ok(
    {
        form_number => 2,
    },
    "Submit decommission form"
);
$mech->title_is('Manoc - Server Hardware S000003', "Back to server page");

my $hw = $schema->resultset('HWAsset')->find({ inventory => 'S000003' });
ok($hw->is_decommissioned);

$mech->follow_link_ok({ text => 'Delete' }, 'Follow delete link');
$mech->submit_form_ok(
    {
        form_number => 2,
    },
    "Submit delete form"
);
$mech->title_is('Manoc - Server Hardware', 'Back to server list page');
$mech->content_lacks( 'S000003', "Server no more in list");
is($schema->resultset('HWAsset')->find({ inventory => 'S000003' }), undef,  "Device is deleted");


$mech->follow_link_ok({ text => 'S000001' }, 'Get first server');
$mech->follow_link_ok({ text => 'Duplicate' }, 'Duplicate');
$mech->submit_form_ok(
    {
        form_number => 2,
    },
    "Submit form using defaults"
);
# fooled my mysql non monotonic primary keys
#$mech->title_is('Manoc - Server Hardware S000004', "Server page");
$mech->text_contains('ShinyBlade', 'Got model from first server');

done_testing();
