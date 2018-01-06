package App::Manoc::DB::Result::Vlan;
#ABSTRACT: A model object representing the table vlan

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('vlan');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0
    },
    vid => {
        data_type   => 'int',
        is_nullable => 0
    },
    name => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0
    },
    description => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 1
    },
    lan_segment_id => {
        data_type      => 'int',
        is_nullable    => 0,
        is_foreign_key => 1
    },
    vlan_range_id => {
        data_type      => 'int',
        is_nullable    => 0,
        is_foreign_key => 1
    }
);

=method devices

Return devices which are using the vlan, using ifstatus info

=cut

sub devices {
    my $self = shift;

    my $ids = $self->interfaces->search(
        {},
        {
            columns  => [qw/device_id/],
            distinct => 1
        }
    )->get_column('device_id')->as_query;

    my $rs = $self->result_source->schema->resultset('App::Manoc::DB::Result::Device');
    $rs = $rs->search( { vid => { -in => $ids } } );

    return wantarray ? $rs->all : $rs;
}

sub update {
    my ( $self, @args ) = @_;

    $self->lan_segment( $self->vlan_range->lan_segment );
    $self->next::method(@args);

    return $self;
}

sub insert {
    my ( $self, @args ) = @_;

    $self->lan_segment( $self->vlan_range->lan_segment );

    $self->next::method(@args);

    return $self;

}

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraints( [ 'lan_segment_id', 'vid' ], ['name'] );

__PACKAGE__->belongs_to(
    lan_segment => 'App::Manoc::DB::Result::LanSegment',
    'lan_segment_id'
);

__PACKAGE__->belongs_to( vlan_range => 'App::Manoc::DB::Result::VlanRange', 'vlan_range_id' );

__PACKAGE__->has_many(
    ip_networks => 'App::Manoc::DB::Result::IPNetwork',
    { 'foreign.vlan_id' => 'self.id' },
    {
        join_type      => 'LEFT',
        cascade_update => 0,
        cascade_delete => 0,
        cascade_copy   => 0,
    }
);

# weak relation with interfaces
__PACKAGE__->has_many(
    interfaces => 'App::Manoc::DB::Result::IfStatus',
    { 'foreign.vlan' => 'self.vid' },
    {
        join_type                 => 'LEFT',
        cascade_delete            => 0,
        cascade_copy              => 0,
        is_foreign_key_constraint => 0,
    }
);

# weak relation with vtp entries
__PACKAGE__->belongs_to(
    vtp_entry => 'App::Manoc::DB::Result::VlanVtp',
    { 'foreign.id' => 'self.vid' },
    {
        join_type                 => 'LEFT',
        is_foreign_key_constraint => 0,
    }
);

1;
