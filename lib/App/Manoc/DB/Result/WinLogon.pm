package App::Manoc::DB::Result::WinLogon;

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->load_components(
    qw(
        +App::Manoc::DB::Helper::Row::TupleArchive
        +App::Manoc::DB::InflateColumn::IPv4
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

__PACKAGE__->resultset_class('App::Manoc::DB::ResultSet::WinLogon');

=for Pod::Coverage  sqlt_deploy_hook
=cut

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
