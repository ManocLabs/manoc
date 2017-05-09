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

# prepare some ipblocks to be used later

$schema->resultset("IPBlock")->create(
    {
        from_addr => App::Manoc::IPAddress::IPv4->new('192.168.1.10'),
        to_addr   => App::Manoc::IPAddress::IPv4->new('192.168.1.100'),
        name      => 'Block01'
    }
);

# visit (empty) ipnetwork list
$mech->get_ok('/ipnetwork');
$mech->title_is('Manoc - List Networks');

like(
    $mech->find_link( text => 'Add' )->url,
    qr|/ipnetwork/create$|,
    "Add link points to ipnetwork/create"
);

# continue testing even if Add link is broken
$mech->get_ok( '/ipnetwork/create', "Create ipnetwork page" );
$mech->submit_form_ok(
    {
        form_id => 'form-ipnetwork',
        fields  => {},
    },
    "Submit uncomplete form",
);
$mech->text_contains('Address field is required');
$mech->text_contains('Prefix field is required');
$mech->text_contains('Name field is required');

# try with a correct form without gw
$mech->submit_form_ok(
    {
        form_id => 'form-ipnetwork',
        fields  => {
            'form-ipnetwork.address' => '192.168.1.0',
            'form-ipnetwork.prefix'  => '24',
            'form-ipnetwork.name'    => 'Net01'
        },
    },
    "Create ipnetwork",
);
$mech->title_is( 'Manoc - Network Net01', 'Network page' );

$mech->get('/ipnetwork');
$mech->text_contains( 'Net01', "New ipnetwork in the list" );

$mech->get( '/ipnetwork/root', "Get top level networks" );
$mech->title_is('Manoc - Top level IP networks');
$mech->text_contains( 'Net01', "New ipnetwork in top nets view" );

$mech->follow_link_ok( { text => 'Net01' }, "Follow link to network page" );
$mech->title_is('Manoc - Network Net01');

$mech->follow_link_ok( { text => 'Edit' }, "Edit ipnetwork page" );

# try with a correct form without gw
$mech->submit_form_ok(
    {
        form_id => 'form-ipnetwork',
        fields  => {
            'form-ipnetwork.default_gw' => '192.168.12.0',
        },
    },
    "Add a bad default gateway",
);
$mech->text_contains( 'Gateway outside network', 'Gateway field has error' );
$mech->submit_form_ok(
    {
        form_id => 'form-ipnetwork',
        fields  => {
            'form-ipnetwork.default_gw' => '192.168.1.254',
        },
    },
    "Add a default gateway",
);
$mech->title_is('Manoc - Network Net01');
$mech->text_contains( '192.168.1.254', 'gateway in network page' );

$mech->follow_link_ok( { text => 'Edit' }, "Edit ipnetwork page" );
$mech->submit_form_ok(
    {
        form_id => 'form-ipnetwork',
        fields  => {
            'form-ipnetwork.vlan' => '1',
        },
    },
    "Set native vlan",
);
$mech->title_is( 'Manoc - Network Net01', 'Back to ipnetwork page' );
$mech->text_contains( 'Block01', "Contained block is listed" );

$mech->get_ok('/ipnetwork/create');
$mech->submit_form_ok(
    {
        form_id => 'form-ipnetwork',
        fields  => {
            'form-ipnetwork.address' => '192.168.1.0',
            'form-ipnetwork.prefix'  => '25',
            'form-ipnetwork.name'    => 'Subnet01'
        },
    },
    "Submit form for first subnet",
);
$mech->title_is( 'Manoc - Network Subnet01', 'Back to ipnetwork page' );
$mech->text_contains( 'Net01', "Super network is listed" );

$schema->resultset("IPNetwork")->create(
    {
        address => App::Manoc::IPAddress::IPv4->new('192.168.1.0'),
        prefix  => '26',
        name    => 'Subnet02'
    }
);

$mech->get('/ipnetwork/root');
$mech->text_contains( 'Net01',    "Root ipnetwork in top netw view" );
$mech->text_contains( 'Subnet01', "New subnetwork in top nets view" );
$mech->text_contains( 'Subnet02', "Subsub network  listed in top nets view" );

$mech->get_ok( '/ipnetwork/', "Get network list" );
$mech->text_contains( 'Net01',    "Root ipnetwork in the list" );
$mech->text_contains( 'Subnet01', "New subnetwork in the list" );
$mech->text_contains( 'Subnet02', "Subsub network  listed in list" );

$schema->resultset("IPNetwork")->create(
    {
        address => App::Manoc::IPAddress::IPv4->new('192.168.2.0'),
        prefix  => '24',
        name    => 'Net02'
    }
);

$mech->get('/ipnetwork/root');
$mech->text_contains( 'Net01',    "First supernet in top nets view" );
$mech->text_contains( 'Net02',    "Second supernet in top nets view" );
$mech->text_contains( 'Subnet01', "Subnetwork in top nets view" );
$mech->text_lacks( 'Subnet02', "Subsub not listed in top nets view" );

$mech->get('/ipnetwork/create');
$mech->submit_form_ok(
    {
        form_id => 'form-ipnetwork',
        fields  => {
            'form-ipnetwork.address' => '192.168.0.0',
            'form-ipnetwork.prefix'  => '16',
            'form-ipnetwork.name'    => 'Supernet01'
        },
    },
    "Submit form for nested subnet",
);
$mech->title_is( 'Manoc - Network Supernet01', 'Back to ipnetwork page' );
$mech->text_contains( 'Net01', "New ipnetwork in the list" );

$mech->get('/ipnetwork/root');
$mech->text_contains( 'Supernet01', "Super network in the list" );
$mech->text_contains( 'Net01',      "Network in the list" );
$mech->follow_link_ok( { text => 'Net01' }, "Follow link to network page" );

$mech->follow_link_ok( { text => 'Delete' }, "Follow delete link" );
# first form is search box
$mech->submit_form_ok( { form_number => 2 }, "Submit delete form" );

$mech->content_lacks( 'Net01',    "No longer in the list" );
$mech->content_lacks( 'Subnet01', "subnetwork not in list" );
$mech->content_lacks( 'Subnet02', "subsubnetwork not in list" );

done_testing();
