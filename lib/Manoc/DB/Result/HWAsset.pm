# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::HWAsset;
use strict;
use warnings;

use base 'DBIx::Class::Core';

use Carp;

use constant {
    TYPE_DEVICE      => 'D',
    TYPE_PRINTER     => 'P',
    TYPE_WORKSTATION => 'W',
    TYPE_SERVER      => 'S',
    TYPE_IPPHONE     => 'p'
};

use constant {
    LOCATION_DISMISSED => 'd',
    LOCATION_WAREHOUSE => 'w',
    LOCATION_RACK      => 'r',
    LOCATION_ROOM      => 'o',
};

our %TYPE = (
    (TYPE_DEVICE)      => { label => 'Device', class => 'Device' },
    (TYPE_SERVER)      => { label => 'Server', class => 'Server' },
    (TYPE_WORKSTATION) => { label => 'Workstation' },
    (TYPE_PRINTER)     => { label => 'Printer' },
    (TYPE_IPPHONE)     => { label => 'VoIP Phone' },
);

__PACKAGE__->load_components(qw/PK::Auto InflateColumn/);

__PACKAGE__->table('hwassets');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    type => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 1,
    },
    location => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 1,
        accessor    => '_location',
    },
    vendor => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 32,
    },
    model => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 32,
    },
    serial => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 32,
    },
    inventory => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 32,
    },
    type => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 1,
    },
    rack_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },
    rack_level => {
        data_type   => 'int',
        is_nullable => 1,
    },
    building_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },
    floor => {
        data_type   => 'varchar',
        size        => '4',
        is_nullable => 1,
    },
    room => {
        data_type   => 'varchar',
        size        => '16',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraints( [qw/inventory/] );

__PACKAGE__->belongs_to( building => 'Manoc::DB::Result::Building', 'building_id', );
__PACKAGE__->belongs_to( rack     => 'Manoc::DB::Result::Rack', 'rack_id' );

__PACKAGE__->might_have( device   => 'Manoc::DB::Result::Device', 'hwasset_id' );

sub in_use {
    my $self = shift;
    return $self->device;
}

sub is_dismissed {
    my $self = shift;
    return $self->_location eq LOCATION_DISMISSED;
}

sub is_in_warehouse {
    my $self = shift;
    return $self->_location eq LOCATION_WAREHOUSE;
}

sub is_in_rack {
    my $self = shift;
    return $self->_location eq LOCATION_RACK;
}

sub sync_location_fields {
    my $self = shift;

    my $location = $self->_location;

    if ($location eq LOCATION_WAREHOUSE ||
            $location eq LOCATION_DISMISSED)
        {
            $self->rack(undef);
            $self->rack_level(undef);
            $self->building(undef);
            $self->floor(undef);
            $self->room(undef);
        }
    if ($location eq LOCATION_ROOM) {
        $self->rack(undef)
    }
    if ($location eq LOCATION_RACK) {
        my $rack = $self->rack;

        $rack or croak "Undefined rack field while location is set to rack";
        $self->building($rack->building);
        $self->room($rack->room);
        $self->floor($rack->floor);
    }
}


sub dismiss {
    my $self = shift;

    $self->_location(LOCATION_DISMISSED);
    $self->sync_location_fields;
}

sub move_to_rack {
    my ($self, $rack) = @_;

    defined($rack) or croak "move_to_rack called with an undef rack";
    my $rack_id = ref($rack) ? $rack->id : $rack;
    $self->_location(LOCATION_RACK);
    $self->rack_id($rack_id);
    $self->sync_location_fields();
}

sub move_to_room {
    my ($self, $building, $floor, $room) = @_;

    defined($building) or croak "Move to room called with an undef building";

    my $building_id = ref($building) ? $building->id : $building;
    $self->_location(LOCATION_ROOM);
    $self->building_id($building_id);
    $self->floor($floor);
    $self->room($room);

    $self->sync_location_fields;
}

sub move_to_warehouse {
    my $self = shift;

    $self->_location(LOCATION_WAREHOUSE);
    $self->sync_location_fields;
}

sub label {
    my $self = shift;

    return $self->inventory . " (" . $self->vendor . " - " . $self->model . ")",
}

sub display_type {
    my $self = shift;

    return $TYPE{$self->type}->{label};
}

sub display_location {
    my $self = shift;

    my $location = $self->_location;

    if ($location eq LOCATION_WAREHOUSE ) {
        return "Warehouse";
    }

    if ( $location eq LOCATION_RACK ) {
        return "Rack " . $self->rack->label;
    }

    if ( $location eq LOCATION_ROOM ) {
        my $location = $self->building->label;
        defined($self->floor) and $location .= " - " . $self->floor;
        defined($self->room)  and $location .= " - " . $self->room;
        return $location;
    }

    if ( $location eq LOCATION_DISMISSED ) {
        return "Dismissed";
    }
}

sub insert {
    my ( $self, @args ) = @_;
    $self->next::method(@args);

    if ( ! defined( $self->inventory ) ) {
        my $inventory = sprintf("%s%06d", $self->type, $self->id);
        $self->inventory($inventory);
        $self->update;
    }
    return $self;
}

#TODO
# - has(service_contract)

no Moose;
1;
