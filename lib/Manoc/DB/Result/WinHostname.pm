# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::WinHostname;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
__PACKAGE__->table('win_hostname');

__PACKAGE__->add_columns(
    'name' => {
        data_type   => 'char',
        size        => 255,
        is_nullable => 0,
    },
    'ipaddr' => {
        data_type      => 'char',
        is_nullable    => 0,
        size           => 15,
        is_foreign_key => 1,
    },
    'firstseen' => {
        data_type   => 'int',
        is_nullable => 0,
        size        => 11
    },
    'lastseen' => {
        data_type     => 'int',
        default_value => 'NULL',
        is_nullable   => 1,
    },
    'archived' => {
        data_type     => 'int',
        default_value => 0,
        is_nullable   => 0,
        size          => 1
    },
);

__PACKAGE__->set_primary_key(qw(name ipaddr firstseen));

sub sqlt_deploy_hook {
    my ( $self, $sqlt_schema ) = @_;

    $sqlt_schema->add_index( name => 'idx_ipaddr', fields => ['ipaddr'] );
}
1;
