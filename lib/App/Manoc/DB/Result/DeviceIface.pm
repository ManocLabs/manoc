package App::Manoc::DB::Result::DeviceIface;
#ABSTRACT: A model object for user notes on device interfaces

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('device_ifaces');

__PACKAGE__->add_columns(
    'id' => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    'device_id' => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    'name' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64
    },
    'vlan_id' => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 1,
    },
    'autocreated' => {
        data_type     => 'int',
        is_nullable   => 0,
        size          => 1,
        default_value => 0,
    },
    'routed' => {
        data_type     => 'int',
        is_nullable   => 0,
        size          => 1,
        default_value => 0,
    },
    'notes' => {
        data_type   => 'text',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraints( deviceifname_dev_name_idx => [ 'device_id', 'name' ] );

__PACKAGE__->belongs_to( device => 'App::Manoc::DB::Result::Device', 'device_id' );

__PACKAGE__->belongs_to(
    vlan => 'App::Manoc::DB::Result::Vlan',
    'vlan_id',
    { join_type => 'LEFT' },
);

__PACKAGE__->might_have(
    cabling => 'App::Manoc::DB::Result::CablingMatrix',
    'interface1_id',
    {
        cascade_copy   => 0,
        cascade_delete => 1,
        cascade_update => 0,
    }
);

__PACKAGE__->add_relationship(
    mat_entry => 'App::Manoc::DB::Result::Mat',
    {
        'foreign.device_id' => 'self.device_id',
        'foreign.interface' => 'self.name'
    },
    {
        accessor                  => 'single',
        join_type                 => 'LEFT',
        is_foreign_key_constraint => 0,
    },
);

__PACKAGE__->might_have(
    status => 'App::Manoc::DB::Result::DeviceIfStatus',
    'interface_id',
    {
        proxy => [
            'description',  'up',        'up_admin',  'duplex',
            'duplex_admin', 'speed',     'stp_state', 'cps_enable',
            'cps_status',   'cps_count', 'vlan'
        ],
        cascade_copy   => 0,
        cascade_delete => 1,
        cascade_update => 0,
    }
);

sub remove_cabling {
    my $self = shift;

    my $cabling = $self->cabling;
    return unless $cabling;

    if ( my $interface2 = $cabling->interface2 ) {
        return $self->result_source->schema->txn_do(
            sub {
                $interface2->cabling->delete;
                $cabling->delete;
            }
        );
    }
    else {
        return $cabling->delete;
    }
}

sub add_cabling_to_interface {
    my ( $self, $interface2 ) = @_;

    $self->result_source->schema->txn_do(
        sub {
            $self->create_related( cabling => { interface2 => $interface2 } );
            $interface2->create_related( cabling => { interface2 => $self } );
        }
    );
}

sub add_cabling_to_nic {
    my ( $self, $nic ) = @_;

    $self->create_related( cabling => { serverhw_nic => $nic } );
}

1;
