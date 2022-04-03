package App::Manoc::DB::Result::HWAsset;
#ABSTRACT: A model object for the parent class of all Hardware assets

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

use Carp;

=head1 CONSTANTS

=head2  Types

To be used in C<type> column.

=for :list
= TYPE_DEVICE
= TYPE_PRINTER
= TYPE_WORKSTATION
= TYPE_SERVER
= TYPE_IPPHONE
=cut

use constant {
    TYPE_DEVICE      => 'D',
    TYPE_PRINTER     => 'P',
    TYPE_WORKSTATION => 'W',
    TYPE_SERVER      => 'S',
    TYPE_IPPHONE     => 'p'
};

=head2 Location

=for :list
= LOCATION_DECOMMISSIONED
= LOCATION_WAREHOUSE
= LOCATION_RACK
= LOCATION_ROOM

=cut

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
    building => 'App::Manoc::DB::Result::Building',
    'building_id',
    { join_type => 'LEFT' }
);

__PACKAGE__->belongs_to(
    rack => 'App::Manoc::DB::Result::Rack',
    'rack_id',
    { join_type => 'LEFT' }
);

__PACKAGE__->belongs_to(
    warehouse => 'App::Manoc::DB::Result::Warehouse',
    'warehouse_id',
    { join_type => 'LEFT' }
);

__PACKAGE__->might_have(
    device => 'App::Manoc::DB::Result::Device',
    'hwasset_id'
);

__PACKAGE__->might_have(
    serverhw => 'App::Manoc::DB::Result::ServerHW',
    'hwasset_id',
    {
        cascade_delete => 1,
    }
);

__PACKAGE__->might_have(
    workstationhw => 'App::Manoc::DB::Result::WorkstationHW',
    'hwasset_id',
    {
        cascade_delete => 1,
    }
);

=method server

Return true if this asset is a serverhw

=cut

sub server {
    my $self = shift;
    $self->serverhw and return $self->serverhw->server;
    return;
}

=method workstation

Return true if this asset is a workstationhw

=cut

sub workstation {
    my $self = shift;
    $self->workstationhw and return $self->workstationhw->workstation;
    return;
}

=method in_use

Return 1 when there is an associated logical item, 0 otherwise.

=cut

sub in_use {
    my $self = shift;
    return ( $self->type eq TYPE_DEVICE && defined( $self->device ) ) ||
        ( $self->type eq TYPE_SERVER && defined( $self->server ) ) ||
        ( $self->type eq TYPE_WORKSTATION && defined( $self->workstation ) );

}

=method is_decommissioned

Return true if decommissioned

=cut

sub is_decommissioned {
    my $self = shift;
    return $self->_location eq LOCATION_DECOMMISSIONED;
}

=method is_in_warehouse

Return true if in warehouse

=cut

sub is_in_warehouse {
    my $self = shift;
    return $self->_location eq LOCATION_WAREHOUSE;
}

=method is_in_rack

Return true if in rack

=cut

sub is_in_rack {
    my $self = shift;
    return $self->_location eq LOCATION_RACK;
}

=method location

Set/get current object location.
If needed rack/floor/room/building fields are cleared.

You cannot use this method to decommission an object, use <decommission>.

=cut

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

=method decommission

Mark object as decommissioned.

=cut

sub decommission {
    my $self      = shift;
    my $timestamp = shift || time();

    $self->location(LOCATION_DECOMMISSIONED);
    $self->locationchange_ts ||
        $self->locationchange_ts($timestamp);
}

=method restore

Undo decommissionining. Set location to warehouse.

=cut

sub restore {
    my $self = shift;

    return unless $self->location eq LOCATION_DECOMMISSIONED;

    $self->location(LOCATION_WAREHOUSE);
    $self->locationchange_ts(undef);
}

=method move_to_rack( $rack )

Set location to rack $rack. Parameter $rack can be an id or row object.

=cut

sub move_to_rack {
    my ( $self, $rack ) = @_;

    defined($rack) or croak "move_to_rack called with an undef rack";
    my $rack_id = ref($rack) ? $rack->id : $rack;
    $self->rack_id($rack_id);
    $self->location(LOCATION_RACK);
}

=method move_to_room($building, $floor, $room)

Set location to building $building, floor $floor and room $room.

=cut

sub move_to_room {
    my ( $self, $building, $floor, $room ) = @_;

    defined($building) or croak "Move to room called with an undef building";

    my $building_id = ref($building) ? $building->id : $building;
    $self->building_id($building_id);
    $self->floor($floor);
    $self->room($room);
    $self->location(LOCATION_ROOM);
}

=method move_to_warehouse( $warehouse )

Set location to warehouse $warehouse.
Parameter $warehouse can be an id or row object.

=cut

sub move_to_warehouse {
    my ( $self, $warehouse ) = @_;

    my $warehouse_id = ref($warehouse) ? $warehouse->id : $warehouse;

    $self->warehouse_id($warehouse_id);
    $self->location(LOCATION_WAREHOUSE);
}

=method label

Return a string describing the object

=cut

sub label {
    my $self = shift;

    return $self->inventory . " (" . $self->vendor . " - " . $self->model . ")",;
}

=method display_type

Return a string describing the object type

=cut

sub display_type {
    my $self = shift;

    return $TYPE{ $self->type }->{label};
}

=method display_location

Return a string describing the object location

=cut

sub display_location {
    my $self = shift;

    my $location = $self->_location;

    if ( $location eq LOCATION_WAREHOUSE ) {
        return defined( $self->warehouse ) ? "Warehouse - " . $self->warehouse->name :
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

=method generate_inventory

Generate a unique inventory identifier and set the inventory field

=cut

sub generate_inventory {
    my $self = shift;

    my $inventory = sprintf( "%s%06d", $self->type, $self->id );
    $self->inventory($inventory);
}

=for POD::Coverate insert

=cut

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

=for POD::Coverate insert

=cut

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
