# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::DB::Result::VirtualInfr;

use parent 'App::Manoc::DB::Result';

use strict;
use warnings;

__PACKAGE__->table('virtual_infr');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },

    name => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 32,
    },

    description => {
        data_type     => 'varchar',
        size          => 64,
        default_value => 'NULL',
        is_nullable   => 1,
    },

    decommissioned => {
        data_type     => 'int',
        size          => '1',
        default_value => '0',
    },

    notes => {
        data_type   => 'text',
        is_nullable => 1,
    },

);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint( [qw/name/] );

__PACKAGE__->has_many(
    virtual_machines => 'App::Manoc::DB::Result::Server',
    { 'foreign.virtinfr_id' => 'self.id' },
);

__PACKAGE__->has_many(
    hypervisors => 'App::Manoc::DB::Result::Server',
    { 'foreign.virtinfr_id' => 'self.id' },
);

1;
