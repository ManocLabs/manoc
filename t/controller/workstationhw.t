#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest;

init_manoctest;

my $mech = get_mech();
my $schema = ManocTest::Schema->get_schema();


my $model  = "DeskCompanion";
my $vendor = "HAL";
my $ram_memory = '4096';
my $cpu_model  = 'i8000';


mech_login;

# visit list
$mech->get_ok( '/workstationhw' );
$mech->title_is('Manoc - Workstation Hardware');

like( $mech->find_link(  text =>'Add' )->url, qr|/workstationhw/create$|, "Add link points to create");

$mech->get_ok('/workstationhw/create');
$mech->title_is('Manoc - Create workstation hardware');
$mech->submit_form_ok({
    form_id => 'form-workstationhw',
    fields => {
        'form-workstationhw.serial'         => 'w001',
        'form-workstationhw.ram_memory'     => $ram_memory,
        'form-workstationhw.cpu_model'      => $cpu_model,
        'form-workstationhw.vendor'         => $vendor,
        'form-workstationhw.model'          => $model,
        # warehouse
        'form-workstationhw.location'       => 'w',
    }
}, "Create workstationhw");
$mech->title_is('Manoc - Workstation Hardware W000001', "Workstation page");

# add another asset just to complicate the scenario
$schema->resultset('HWAsset')->create({
    type       => App::Manoc::DB::Result::HWAsset->TYPE_DEVICE,
    vendor     => 'IQ',
    model      => 'MegaPort 24',
    serial     => 'Test04',
});

$mech->get_ok('/workstationhw/create');
$mech->title_is('Manoc - Create workstation hardware');
$mech->submit_form_ok({
    form_id => 'form-workstationhw',
    fields => {
        'form-workstationhw.ram_memory'     => $ram_memory,
        'form-workstationhw.cpu_model'      => $cpu_model,
        'form-workstationhw.vendor'         => $vendor,
        'form-workstationhw.model'          => $model,
        'form-workstationhw.serial'         => 'w002',
        # warehouse
        'form-workstationhw.location'       => 'w',
    }
}, "Create another workstationhw");
$mech->title_is('Manoc - Workstation Hardware W000003', "Workstation page");

# cannot be done with ajax
#$mech->get_ok( '/workstationhw', "Workstation list" );
#$mech->follow_link_ok({ text => 'W000003' }, 'Follow link from list');

$mech->follow_link_ok({ text => 'Edit' }, 'Follow edit link');
$mech->title_is('Manoc - Edit workstation hardware');
$mech->submit_form_ok({
    form_id => 'form-workstationhw',
    fields => {
        'form-workstationhw.ram_memory'     => $ram_memory,
        'form-workstationhw.cpu_model'      => $cpu_model,
        'form-workstationhw.vendor'         => $vendor,
        'form-workstationhw.serial'         => 'w002',
        'form-workstationhw.model'          => 'YWorkstation',
        # warehouse
        'form-workstationhw.location'       => 'w',
        'form-workstationhw.storage1'       => '10',
        'form-workstationhw.storage2'       => '20',

    }
}, "Edit workstationhw");
$mech->title_is('Manoc - Workstation Hardware W000003', "Back to workstation page");
$mech->text_contains("YWorkstation", "Workstation page contains new model name");

$mech->follow_link_ok({ text => 'Decommission' }, 'Follow decommision link');
$mech->submit_form_ok(
    {
        form_number => 2,
    },
    "Submit decommission form"
);
$mech->title_is('Manoc - Workstation Hardware W000003', "Back to workstation page");

my $hw = $schema->resultset('HWAsset')->find({ inventory => 'W000003' });
ok($hw->is_decommissioned);

$mech->follow_link_ok({ text => 'Delete' }, 'Follow delete link');
$mech->submit_form_ok(
    {
        form_number => 2,
    },
    "Submit delete form"
);
$mech->title_is('Manoc - Workstation Hardware', 'Back to workstation list page');
$mech->content_lacks( 'W000003', "Workstation no more in list");
is($schema->resultset('HWAsset')->find({ inventory => 'W000003' }), undef,  "Device is deleted");


$mech->get_ok('workstationhw/1', 'Get first workstation');
$mech->follow_link_ok({ text => 'Duplicate' }, 'Duplicate');
$mech->submit_form_ok(
    {
        form_number => 2,
    },
    "Submit form using defaults"
);
# fooled by non monotonic primary keys
#$mech->title_is('Manoc - Workstation Hardware S000004', "Workstation page");
$mech->text_contains($model, 'Got model from first workstation');

done_testing();
