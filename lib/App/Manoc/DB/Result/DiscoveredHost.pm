package App::Manoc::DB::Result::DiscoveredHost;
#ABSTRACT: A model object for automatically discovered hosts

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->load_components(qw/+App::Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('discovered_hosts');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    session_id => {
        data_type      => 'int',
        is_nullable    => 0,
        is_foreign_key => 1,
    },
    address => {
        data_type    => 'varchar',
        is_nullable  => 0,
        size         => 15,
        ipv4_address => 1,
    },
    hostname => {
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
    serial => {
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
    os => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    os_ver => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'NULL',
        is_nullable   => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [qw/session_id address/] );

__PACKAGE__->belongs_to(
    session => 'App::Manoc::DB::Result::DiscoverSession',
    'session_id'
);

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
