# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::WinLogon;

use parent 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->load_components(
    qw(
        +Manoc::DB::InflateColumn::IPv4
        +Manoc::DB::Helper::Row::TupleArchive
        )
);

__PACKAGE__->table('win_logon');

__PACKAGE__->add_columns(
    'user' => {
        data_type   => 'char',
        size        => 255,
        is_nullable => 0,
    },
    'ipaddr' => {
        data_type    => 'char',
        is_nullable  => 0,
        size         => 15,
        ipv4_address => 1,
    },
);

__PACKAGE__->set_tuple_archive_columns(qw(user ipaddr));

__PACKAGE__->set_primary_key(qw(user ipaddr firstseen));

__PACKAGE__->resultset_class('Manoc::DB::ResultSet::WinLogon');

sub sqlt_deploy_hook {
    my ( $self, $sqlt_schema ) = @_;

    $sqlt_schema->add_index(
        name   => 'idx_winlogon_user',
        fields => ['user']
    );
    $sqlt_schema->add_index(
        name   => 'idx_winlogon_ipaddr',
        fields => ['ipaddr']
    );
}

1;
