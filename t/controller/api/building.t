#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Deep;

use lib "t/lib";

use ManocTest;

init_manoctest;

my $mech = get_mech();
my $json;

mech_init_httpbasic();

my $API_PREFIX      = '/api/v1';
my $building_fields = {
    'name'        => 'B01',
    'description' => 'Test desc',
    'notes'       => 'Test note',
    },

    $mech->get_ok( "$API_PREFIX/building", "Get building list" );
$json = $mech->json_ok();

is_deeply( $json, [], "Building list is empty" );

$mech->post_json_ok( "$API_PREFIX/building", $building_fields, "Create a building" );
$json = $mech->json_ok();

cmp_ok( $json->{status}, 'eq', 'success', "Status is 'success'" ) || diag explain $json;

my $object_id = $json->{object_id};
ok( defined($object_id), "Building creation returns object_id" ) || diag explain $json;

$mech->get_ok("$API_PREFIX/building/$object_id");
$json = $mech->json_ok();

cmp_deeply( $json, superhashof($building_fields), "Got the correct fields in building" );
ok( defined( $json->{label} ), "Building contains label" ) || diag explain $json;

$mech->post_json_ok(
    "$API_PREFIX/building/$object_id",
    { notes => 'new note' },
    "Modify a building"
);
$json = $mech->json_ok();
cmp_ok( $json->{status}, 'eq', 'success', "Status is 'success'" ) || diag explain $json;

$mech->get_ok("$API_PREFIX/building/$object_id");
$json = $mech->json_ok();
cmp_ok( $json->{notes}, 'eq', 'new note', "Building contains modified field" ) ||
    diag explain $json;

$mech->get_ok( "$API_PREFIX/building", "Get building list" );
$json = $mech->json_ok();
cmp_ok( $json->[0]->{id}, '==', $object_id, 'Object in list' ) || diag explain $json;

done_testing();
