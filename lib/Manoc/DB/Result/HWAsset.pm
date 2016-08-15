# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::HWAsset;
use Moose;

extends 'DBIx::Class::Core';

use constant {
    TYPE_DEVICE      => 'D',
    TYPE_PRINTER     => 'P',
    TYPE_WORKSTATION => 'W',
    TYPE_SERVER      => 'S',
    TYPE_IPPHONE     => 'p'
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
        is_nullable => 0,
        size        => 32,
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
    in_warehouse => {
        data_type     => 'int',
        size          => '1',
        default_value => '1',
    },
    dismissed => {
        data_type     => 'int',
        size          => '1',
        default_value => '0',
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraints( [qw/inventory/] );

__PACKAGE__->belongs_to( building => 'Manoc::DB::Result::Building', 'building_id', );
__PACKAGE__->belongs_to( rack     => 'Manoc::DB::Result::Rack', 'rack_id' );

__PACKAGE__->might_have( device   => 'Manoc::DB::Result::Device', 'hwasset_id' );

around "rack" => sub {
    my ( $orig, $self ) = ( shift, shift );

    if (@_) {
        my $rack = $_[0];
        if ( $rack ) {
            $self->room($rack->room);
            $self->building_id($rack->building_id);
            $self->in_warehouse(0);
        }
    }

    $self->$orig(@_);
};


around "building" => sub {
    my ( $orig, $self ) = ( shift, shift );

    if (@_) {
        my $building = $_[0];
        if ( $building ) {
            $self->in_warehouse(0);
        }
    }

    $self->$orig(@_);
};

sub label {
    my $self = shift;

    return $self->inventory . " (" . $self->vendor . " - " . $self->model . ")",
}

sub location {
    my $self = shift;

    if ($self->in_warehouse) {
        return "Warehouse";
    }

    if ( $self->rack ) {
        return "Rack " . $self->rack->label;
    }

    my $location = "";
    if ( $self->building ) {
        $location = $self->building->label;
        defined($self->floor) and $location .= " Floor " . $self->floor;
        defined($self->room)  and $location .= " Room " . $self->room;
    }
    return $location;
}


#TODO
# - has(service_contract)

no Moose;
1;
