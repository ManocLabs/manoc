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

# visit list
$mech->get_ok('/virtualmachine');
$mech->title_is('Manoc - Virtual Machines');

like( $mech->find_link( text => 'Add' )->url,
    qr|/virtualmachine/create$|, "Add link points to create" );

$mech->get_ok('/virtualmachine/create');
$mech->title_is('Manoc - Create virtual machine');
$mech->submit_form_ok(
    {
        form_id => 'form-virtualmachine',
        fields  => {
            'form-virtualmachine.ram_memory' => '16000',
            'form-virtualmachine.vcpus'      => 1,
            'form-virtualmachine.name'       => 'VMnew',
        }
    },
    "Create virtualmachine"
);
$mech->title_is( 'Manoc - Virtual Machine VMnew', "VM page" );

$mech->get('/virtualmachine');
$mech->follow_link_ok( { text => 'VMnew' }, 'Follow link from list' );
$mech->follow_link_ok( { text => 'Edit' },  'Follow edit link' );
$mech->title_is('Manoc - Edit virtual machine');
$mech->submit_form_ok(
    {
        form_id => 'form-virtualmachine',
        fields  => {
            'form-virtualmachine.name' => 'VM001',
        }
    },
    "Edit virtualmachine"
);
$mech->title_is( 'Manoc - Virtual Machine VM001', "Back to vm page, new name" );

$mech->follow_link_ok( { text => 'Decommission' }, 'Follow decommision link' );
$mech->submit_form_ok(
    {
        form_number => 2,
    },
    "Submit decommission form"
);
$mech->title_is( 'Manoc - Virtual Machine VM001', "Back to vm page" );

my $hw = $schema->resultset('VirtualMachine')->find( { name => 'VM001' } );
ok( $hw->decommissioned, "VM is decommissioned in DB" );

$mech->follow_link_ok( { text => 'Delete' }, 'Follow delete link' );
$mech->submit_form_ok(
    {
        form_number => 2,
    },
    "Submit delete form"
);
$mech->title_is( 'Manoc - Virtual Machines', 'Back to list page' );
$mech->content_lacks( 'VM001', "VM no more in list" );
is( $schema->resultset('VirtualMachine')->find( { name => 'VM001' } ), undef, "VM is deleted" );

done_testing();
