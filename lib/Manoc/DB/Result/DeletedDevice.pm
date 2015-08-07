# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::DeletedDevice;
use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/PK::Auto Core InflateColumn/);

__PACKAGE__->table('deleted_devices');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    ipaddr => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 15,
    },
    name => {
        data_type     => 'varchar',
        size          => 128,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    model => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    vendor => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    timestamp => {
        data_type     => 'int',
        default_value => '0',
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many( mat_assocs => 'Manoc::DB::Result::MatArchive', 'device_id' );

__PACKAGE__->inflate_column(
			    ipaddr => {
				       inflate =>
				       sub { return Manoc::IpAddress::Ipv4->new({ padded => $_[0] }) if defined($_[0]) },
				       deflate => sub { return scalar $_[0]->padded if defined($_[0]) },
				      }
			   );


1;
