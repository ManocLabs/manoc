# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::WinLogon;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
__PACKAGE__->table('win_logon');

__PACKAGE__->add_columns(
    'user' => {
        data_type   => 'char',
        size        => 255,
        is_nullable => 0,
    },
    'ipaddr' => {
        data_type   => 'char',
        is_nullable => 0,
        size        => 15,
    },
    'firstseen' => {
        data_type   => 'int',
        is_nullable => 0,
    },
    'lastseen' => {
        data_type   => 'int',
        is_nullable => 0,
    },
    'archived' => {
        data_type     => 'int',
        is_nullable   => 0,
        size          => 1,
        default_value => '0',
    },
);

__PACKAGE__->set_primary_key(qw(user ipaddr firstseen));

sub sqlt_deploy_hook {
    my ( $self, $sqlt_schema ) = @_;

    $sqlt_schema->add_index( name => 'idx_user',   fields => ['user'] );
    $sqlt_schema->add_index( name => 'idx_ipaddr', fields => ['ipaddr'] );
}

1;
