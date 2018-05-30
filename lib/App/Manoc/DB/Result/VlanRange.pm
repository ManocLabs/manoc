package App::Manoc::DB::Result::VlanRange;
#ABSTRACT:  A model object representing the table vlan_range
use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

use Carp;

__PACKAGE__->load_components(qw/+App::Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('vlan_range');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0
    },
    lan_segment_id => {
        data_type      => 'int',
        is_nullable    => 0,
        is_foreign_key => 1
    },
    name => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
    },
    start => {
        data_type   => 'int',
        is_nullable => 0,
        extras      => { unsigned => 1 }
    },
    end => {
        data_type   => 'int',
        is_nullable => 0,
        extras      => { unsigned => 1 }
    },
    description => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 1
    },
    notes => {
        data_type   => 'text',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( ['name'] );
__PACKAGE__->has_many(
    vlans => 'App::Manoc::DB::Result::Vlan',
    'vlan_range_id',
    {
        join_type      => 'LEFT',
        cascade_delete => 0,
        cascade_copy   => 0,
    }
);

__PACKAGE__->belongs_to(
    lan_segment => 'App::Manoc::DB::Result::LanSegment',
    'lan_segment_id'
);

sub update {
    my ( $self, @args ) = @_;

    my $start = $self->start;
    my $end   = $self->end;

    # wrap all the updates in a transaction
    my $guard = $self->result_source->schema->txn_scope_guard;

    # create this range
    $self->next::method(@args);

    my $segment = $self->lan_segment;

    # update vlans in the same segment which are inside the range
    foreach my $vlan ( $segment->vlans ) {
        if ( $vlan->vid >= $start && $vlan->vid <= $end ) {
            $vlan->vlan_range($self);
            $vlan->update;
        }
        elsif ( $vlan->vlan_range_id && $vlan->vlan_range_id == $self->id ) {
            # the vlan doesn't belong anymore to this range
            $vlan->vlan_range(undef);
            $vlan->update;
        }
    }

    # end of transaction
    $guard->commit;

    return $self;
}

sub insert {
    my ( $self, @args ) = @_;

    my $start = $self->start;
    my $end   = $self->end;

    my $guard = $self->result_source->schema->txn_scope_guard;

    # create this range
    $self->next::method(@args);

    my $segment = $self->lan_segment;

    # update vlans in the same segment which are inside the range
    foreach my $vlan ( $segment->vlans ) {
        if ( $vlan->id >= $start && $vlan->id <= $end ) {
            $vlan->vlan_range($self);
            $vlan->update;
        }
    }

    # end of transaction
    $guard->commit;

    return $self;
}

1;
