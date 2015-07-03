# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::CDPNeigh;

use base qw(DBIx::Class);

__PACKAGE__->load_components(qw/PK::Auto Core InflateColumn/);

__PACKAGE__->table('cdp_neigh');
__PACKAGE__->add_columns(
    'from_device' => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    'from_interface' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64
    },
    'to_device' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 15
    },
    'to_interface' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64
    },
    'last_seen' => {
        data_type   => 'int',
        is_nullable => 0,
    },
    'remote_id' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 64
    },
    'remote_type' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 64
    },
);

__PACKAGE__->set_primary_key(
    qw(from_device from_interface
        to_device to_interface)
);

__PACKAGE__->belongs_to(
    from_device => 'Manoc::DB::Result::Device',
    { 'foreign.id' => 'self.from_device' }
);

__PACKAGE__->inflate_column(
    to_device => {
	inflate =>
	    sub { return Manoc::IpAddress::Ipv4->new({ padded => $_[0] }) if defined($_[0]) },
	deflate => sub { return scalar $_[0]->padded if defined($_[0]) },
    }
);

# TODO is_foreign_key_constraint doesn't work!!
#__PACKAGE__->might_have(to_device_info => 'Manoc::DB::Result::Device',
#			{ 'foreign.id' => 'self.to_device' },
#			{
#			    cascade_delete => 0,
#			    is_foreign_key_constraint => 0,
#			}
#			);

=head1 NAME

Manoc::DB::Result::CDPNeigh - A model object representing a CDP relationship.

=head1 DESCRIPTION

This is an object that represents a CDP entry. It uses DBIx::Class
(aka, DBIC) to do ORM.

=cut

1;
