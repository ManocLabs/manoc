# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Vlan;
use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->table('vlan');

__PACKAGE__->add_columns(
    id => {
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
    vlan_range_id => {
        data_type      => 'int',
        is_nullable    => 0,
        is_foreign_key => 1
    }
);

# return devices which are using the vlan, using ifstatus info
sub devices {
    my $self = shift;

    my $ids = $self->interfaces->search(
        {},
        {
            columns  => [qw/device_id/],
            distinct => 1
        }
    )->get_column('device_id')->as_query;

    my $rs = $self->result_source->schema->resultset('Manoc::DB::Result::Device');
    return $rs->search( { id => { -in => $ids } } );
}

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to( vlan_range => 'Manoc::DB::Result::VlanRange', 'vlan_range_id' );
__PACKAGE__->has_many(
    ip_networks => 'Manoc::DB::Result::IPNetwork',
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
    interfaces => 'Manoc::DB::Result::IfStatus',
    { 'foreign.vlan' => 'self.id' },
    {
        join_type                 => 'LEFT',
        cascade_delete            => 0,
        cascade_copy              => 0,
        is_foreign_key_constraint => 0,
    }
);

# weak relation with vtp entries
__PACKAGE__->belongs_to(
    vtp_entry => 'Manoc::DB::Result::VlanVtp',
    { 'foreign.id' => 'self.id' },
    {
        join_type                 => 'LEFT',
        is_foreign_key_constraint => 0,
    }
);

=head1 NAME

Manoc::DB::Result::Vlan - A model object representing the table vlan

=head1 DESCRIPTION

This is an object that represents a row in the 'vlan' table of your
application database.  It uses DBIx::Class (aka, DBIC) to do ORM.

=cut

1;
