# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::HWAsset;

use parent 'Manoc::DB::Result';

use strict;
use warnings;

use Carp;

use constant {
    TYPE_DEVICE      => 'D',
    TYPE_PRINTER     => 'P',
    TYPE_WORKSTATION => 'W',
    TYPE_SERVER      => 'S',
    TYPE_IPPHONE     => 'p'
};

use constant {
    LOCATION_DECOMMISSIONED => 'd',
    LOCATION_WAREHOUSE      => 'w',
    LOCATION_RACK           => 'r',
    LOCATION_ROOM           => 'o',
};

use constant DEFAULT_LOCATION => LOCATION_WAREHOUSE;

our %TYPE = (
    (TYPE_DEVICE)      => { label => 'Device', class => 'Device' },
    (TYPE_SERVER)      => { label => 'Server', class => 'Server' },
    (TYPE_WORKSTATION) => { label => 'Workstation' },
    (TYPE_PRINTER)     => { label => 'Printer' },
    (TYPE_IPPHONE)     => { label => 'VoIP Phone' },
);

__PACKAGE__->table('hwassets');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    type => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 1,
    },
    location => {
        data_type     => 'varchar',
        is_nullable   => 0,
        default_value => DEFAULT_LOCATION,
        size          => 1,
        accessor      => '_location',
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
    warehouse_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
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
    locationchange_ts => {
        data_type     => 'int',
        default_value => 'NULL',
        is_nullable   => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraints( [qw/inventory/] );

__PACKAGE__->belongs_to(
    building => 'Manoc::DB::Result::Building',
    'building_id',
    { join_type => 'left' }
);

__PACKAGE__->belongs_to(
    rack => 'Manoc::DB::Result::Rack',
    'rack_id',
    { join_type => 'left' }
);

__PACKAGE__->belongs_to(
    warehouse => 'Manoc::DB::Result::Warehouse',
    'warehouse_id',
    { join_type => 'left' }
);

__PACKAGE__->might_have(
    device => 'Manoc::DB::Result::Device',
    'hwasset_id'
);

__PACKAGE__->might_have(
    serverhw => 'Manoc::DB::Result::ServerHW',
    'hwasset_id',
    {
        cascade_delete => 1,
    }
);

__PACKAGE__->might_have(
    workstationhw => 'Manoc::DB::Result::WorkstationHW',
    'hwasset_id',
    {
        cascade_delete => 1,
    }
);

sub server {
    my $self = shift;
    $self->serverhw and return $self->serverhw->server;
    return undef;
}

sub workstation {
    my $self = shift;
    $self->workstationhw and return $self->workstationhw->workstation;
    return undef;
}

=head2 in_use

Return 1 when there is an associated logical item, 0 otherwise.

=cut

sub in_use {
    my $self = shift;
    return ( $self->type eq TYPE_DEVICE && defined( $self->device ) ) ||
        ( $self->type eq TYPE_SERVER && defined( $self->server ) ) ||
        ( $self->type eq TYPE_WORKSTATION && defined( $self->workstation ) );

}

sub is_decommissioned {
    my $self = shift;
    return $self->_location eq LOCATION_DECOMMISSIONED;
}

sub is_in_warehouse {
    my $self = shift;
    return $self->_location eq LOCATION_WAREHOUSE;
}

sub is_in_rack {
    my $self = shift;
    return $self->_location eq LOCATION_RACK;
}

sub location {
    my $self = shift;

    if (@_) {
        my $location = shift;
        if ( $location eq LOCATION_DECOMMISSIONED ) {
            $self->rack(undef);
            $self->rack_level(undef);
            $self->building(undef);
            $self->floor(undef);
            $self->room(undef);
            $self->warehouse(undef);
        }
        elsif ( $location eq LOCATION_WAREHOUSE ) {
            my $warehouse = $self->warehouse;
            if ($warehouse) {
                $self->building( $warehouse->building );
                $self->room( $warehouse->room );
                $self->floor( $warehouse->floor );
            }
            $self->rack(undef);
            $self->rack_level(undef);
        }
        elsif ( $location eq LOCATION_ROOM ) {
            $self->rack(undef);
            $self->warehouse(undef);
        }
        elsif ( $location eq LOCATION_RACK ) {
            my $rack = $self->rack;
            if ($rack) {
                $self->building( $rack->building );
                $self->room( $rack->room );
                $self->floor( $rack->floor );
            }
            $self->warehouse(undef);
        }
        else {
            croak "Invalid location value";
            return;
        }
        $self->_location($location);
    }
    return $self->_location;
}

sub decommission {
    my $self = shift;
    my $timestamp = shift || time();

    $self->location(LOCATION_DECOMMISSIONED);
    $self->locationchange_ts ||
        $self->locationchange_ts($timestamp);
}

sub restore {
    my $self = shift;

    return unless $self->location eq LOCATION_DECOMMISSIONED;

    $self->location(LOCATION_WAREHOUSE);
    $self->locationchange_ts(undef);
}

sub move_to_rack {
    my ( $self, $rack ) = @_;

    defined($rack) or croak "move_to_rack called with an undef rack";
    my $rack_id = ref($rack) ? $rack->id : $rack;
    $self->rack_id($rack_id);
    $self->location(LOCATION_RACK);
}

sub move_to_room {
    my ( $self, $building, $floor, $room ) = @_;

    defined($building) or croak "Move to room called with an undef building";

    my $building_id = ref($building) ? $building->id : $building;
    $self->building_id($building_id);
    $self->floor($floor);
    $self->room($room);
    $self->location(LOCATION_ROOM);
}

sub move_to_warehouse {
    my ( $self, $warehouse ) = @_;

    my $warehouse_id = ref($warehouse) ? $warehouse->id : $warehouse;

    $self->warehouse_id($warehouse_id);
    $self->location(LOCATION_WAREHOUSE);
}

sub label {
    my $self = shift;

    return $self->inventory . " (" . $self->vendor . " - " . $self->model . ")",;
}

sub display_type {
    my $self = shift;

    return $TYPE{ $self->type }->{label};
}

sub display_location {
    my $self = shift;

    my $location = $self->_location;

    if ( $location eq LOCATION_WAREHOUSE ) {
        return
            defined( $self->warehouse ) ? "Warehouse - " . $self->warehouse->name :
            "Warehouse";
    }

    if ( $location eq LOCATION_RACK ) {
        return "Rack " . $self->rack->label;
    }

    if ( $location eq LOCATION_ROOM ) {
        my $location = $self->building->label;
        defined( $self->floor ) and $location .= " - " . $self->floor;
        defined( $self->room )  and $location .= " - " . $self->room;
        return $location;
    }

    if ( $location eq LOCATION_DECOMMISSIONED ) {
        return "Decommissioned";
    }
}

sub generate_inventory {
    my $self = shift;

    my $inventory = sprintf( "%s%06d", $self->type, $self->id );
    $self->inventory($inventory);
}

sub insert {
    my ( $self, @args ) = @_;

    $self->location or
        $self->location(LOCATION_WAREHOUSE);
    $self->next::method(@args);

    if ( !defined( $self->inventory ) ) {
        $self->generate_inventory;
        $self->update;
    }
    return $self;
}

sub update {
    my ( $self, @args ) = @_;
    $self->next::method(@args);

    if ( !defined( $self->inventory ) ) {
        $self->generate_inventory;
        $self->update;
    }
    return $self;
}

#TODO
# - has(service_contract)

1;
