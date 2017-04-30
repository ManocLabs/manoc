package App::Manoc::DB::Result::ServerAddr;

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->load_components(qw/+App::Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('server_addr');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },

    server_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },

    ipaddr => {
        data_type    => 'varchar',
        is_nullable  => 1,
        size         => 15,
        ipv4_address => 1,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint( [ 'server_id', 'ipaddr' ] );

__PACKAGE__->belongs_to(
    server => 'App::Manoc::DB::Result::Server',
    { 'foreign.id' => 'self.server_id' }
);

=head1 NAME

App::Manoc::DB::Result::ServerAddr - Server additional network addresses

=head1 DESCRIPTION

A model object to mantain netwalker configuration for a server.

=cut

1;
