# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::DeviceConfig;

use parent 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table('device_config');
__PACKAGE__->add_columns(
    'device' => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    'config' => {
        data_type   => 'text',
        is_nullable => 0
    },
    'prev_config' => {
        data_type   => 'text',
        is_nullable => 1,
    },
    'config_date' => {
        data_type   => 'int',
        is_nullable => 0,
        size        => 11
    },
    'prev_config_date' => {
        data_type   => 'int',
        size        => 11,
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key("device");

__PACKAGE__->belongs_to(
    device => 'Manoc::DB::Result::Device',
    { 'foreign.id' => 'self.device' }
);

=head1 NAME

Manoc::DB::Result::DeviceConfig - A model object to mantain the devices configuration backup.

=head1 DESCRIPTION

This is an object that represents a CDP entry. It uses DBIx::Class
(aka, DBIC) to do ORM.

=cut

1;
