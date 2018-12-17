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

# reusable fields assignments
my %common_fields = (
    'ram_memory' => '16000',
    'cpu_model'  => 'E1234',
    'vendor'     => 'Moon',
    'model'      => 'ShinyBlade',
    # warehouse
    'location' => 'w',
);

# create a nic type
my $nic_type = $schema->resultset("NICType")->find_or_create(
    {
        name     => 'Eth 100',
    }
);
ok( $nic_type, "Create a test NIC type");

# visit list
$mech->get_ok('/serverhw');
$mech->title_is('Manoc - Server Hardware');

like( $mech->find_link( text => 'Add' )->url,
    qr|/serverhw/create$|, "Add link points to create" );

$mech->get_ok('/serverhw/create');
$mech->title_is('Manoc - Create server hardware');
$mech->submit_form_ok(
    {
        form_id => 'form-serverhw',
        fields  => {
            %common_fields,
            'serial'     => 'moo001',
        }
    },
    "Create serverhw"
);
$mech->title_is( 'Manoc - Server Hardware S000001', "Server page" );

# add another asset just to complicate the scenario
$schema->resultset('HWAsset')->create(
    {
        type   => App::Manoc::DB::Result::HWAsset->TYPE_DEVICE,
        vendor => 'IQ',
        model  => 'MegaPort 24',
        serial => 'Test04',
    }
);

$mech->get_ok('/serverhw/create');
$mech->title_is('Manoc - Create server hardware');
$mech->submit_form_ok(
    {
        form_id => 'form-serverhw',
        fields  => {
            %common_fields,

            'serial'     => 'moo002',
        }
    },
    "Create another serverhw"
);
$mech->title_is( 'Manoc - Server Hardware S000003', "Server page" );

$mech->get_ok( '/serverhw', "Server list" );
$mech->follow_link_ok( { text_regex => qr/^S000003/ }, 'Follow link from list' );

$mech->follow_link_ok( { text => 'Edit' }, 'Follow edit link' );
$mech->title_is('Manoc - Edit server hardware');
$mech->submit_form_ok(
    {
        form_id => 'form-serverhw',
        fields  => {
            %common_fields,
            'serial'   => 'moo002',
            'model'    => 'YServer',
            'storage1' => '10',
            'storage2' => '20',
        }
    },
    "Edit serverhw"
);
$mech->title_is( 'Manoc - Server Hardware S000003', "Back to server page" );
$mech->text_contains( "YServer", "Server page contains new model name" );

$mech->follow_link_ok( { text => 'Decommission' }, 'Follow decommision link' );
$mech->submit_form_ok(
    {
        form_number => 2,
    },
    "Submit decommission form"
);
$mech->title_is( 'Manoc - Server Hardware S000003', "Back to server page" );

my $hw = $schema->resultset('HWAsset')->find( { inventory => 'S000003' } );
ok( $hw->is_decommissioned );

$mech->follow_link_ok( { text => 'Delete' }, 'Follow delete link' );
$mech->submit_form_ok(
    {
        form_number => 2,
    },
    "Submit delete form"
);
$mech->title_is( 'Manoc - Server Hardware', 'Back to server list page' );
$mech->content_lacks( 'S000003', "Server no more in list" );
is( $schema->resultset('HWAsset')->find( { inventory => 'S000003' } ),
    undef, "Device is deleted" );

$mech->follow_link_ok( { text_regex => qr/^S000001/ }, 'Get first server' );
$mech->follow_link_ok( { text       => 'Duplicate' },  'Duplicate' );
$mech->submit_form_ok(
    {
        form_number => 2,
    },
    "Submit form using defaults"
);
# fooled my mysql non monotonic primary keys
#$mech->title_is('Manoc - Server Hardware S000004', "Server page");
$mech->text_contains( 'ShinyBlade', 'Got model from first server' );


# test NICs

$mech->get_ok('/serverhw/create');
$mech->submit_form_ok(
    {
        form_id => 'form-serverhw',
        fields  => {
            %common_fields,

            'serial'     => 'moo004',
            'inventory'  => 'N01',

            'nics.0.macaddr'  => '00:00:00:11:22:33',
            'nics.0.name'     => 'eth0',
            'nics.0.nic_type' =>  $nic_type->id,
            'nics.1.macaddr'  => '00:00:00:11:22:34',
            'nics.1.nic_type' =>  $nic_type->id,
        }
    },
    "Create a server with a NIC serverhw"
);
$mech->title_is( 'Manoc - Server Hardware N01', "Server page" );
$mech->text_contains( 'eth0', "First nic name found" );
$mech->text_contains( '00:00:00:11:22:33', "First nic addr found" );
$mech->text_contains( 'nic1', "Second nic name (auto) found" );
$mech->text_contains( '00:00:00:11:22:34', "Second nic addr found" );


$mech->get_ok('/serverhw/create');
$mech->submit_form_ok(
    {
        form_id => 'form-serverhw',
        fields  => {
            %common_fields,
            'inventory'  => 'N02',

            'nics.0.macaddr' => '00:00:00:11:22:33',
            'nics.0.name'    => 'eth0',
            'nics.0.nic_type' =>  $nic_type->id,
        }
    },
    "Create a server with a NIC (duplicated maccaddr)"
);
$mech->text_contains( 'Duplicate value for Macaddr', "Got error for Duplicate value for Macaddr" );

$mech->get_ok('/serverhw/create');
$mech->submit_form_ok(
    {
        form_id => 'form-serverhw',
        fields  => {
            %common_fields,
            'inventory'  => 'N02',

            'nics.0.macaddr' => 'aa:bb:cc:dd:ee:ff',
            'nics.0.name'    => 'eth0',
            'nics.0.nic_type' =>  $nic_type->id,

            'nics.1.macaddr' => 'aa:bb:cc:dd:ee:ff',
            'nics.1.name'    => 'eth0',
            'nics.1.nic_type' =>  $nic_type->id,
        }
    },
    "Create a server with a NIC (duplicated maccaddr)"
);
$mech->text_contains( 'Duplicate value for Macaddr', "Got error for  Duplicate value for Macaddr" );
$mech->text_contains( 'Duplicate value for NIC', "Got error for Duplicate value for Name" );


done_testing();
