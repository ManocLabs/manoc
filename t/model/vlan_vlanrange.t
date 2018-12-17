#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib "t/lib";

use ManocTest::Schema;

my $schema = ManocTest::Schema->connect();
ok( $schema, "Create schema" );

my $rs = $schema->resultset('LanSegment');
ok( $rs, 'LanSegment Resultset' );

my $segment = $rs->update_or_create(
    {
        name => 'default',
    }
);
my $vlan1  = $segment->add_to_vlans( { name => 'native', vid => 1 } );
my $vlan2  = $segment->add_to_vlans( { name => 'v2',     vid => 2 } );
my $vlan11 = $segment->add_to_vlans( { name => 'v11',    vid => 11 } );

my $vlan_range = $segment->add_to_vlan_ranges(
    {
        name        => 'sample',
        description => 'sample range',
        start       => 1,
        end         => 10,
    }
);

$vlan_range->discard_changes();
$vlan1->discard_changes();
$vlan2->discard_changes();
$vlan11->discard_changes();

ok( $vlan1->vlan_range && $vlan1->vlan_range->id == $vlan_range->id,
    "Automatic range association" );
ok( $vlan2->vlan_range && $vlan2->vlan_range->id == $vlan_range->id,
    "Automatic range association" );
is( $vlan11->vlan_range, undef, "VLAN outside range is not associated" );

$vlan_range->start(2);
$vlan_range->update->discard_changes;
$vlan1->discard_changes();
$vlan2->discard_changes();
$vlan11->discard_changes();

is( $vlan1->vlan_range, undef, "Automatic range de-association" );
ok(
    $vlan2->vlan_range && $vlan2->vlan_range->id == $vlan_range->id,
    "Un range update in range vlan are still associated"
);

done_testing();
