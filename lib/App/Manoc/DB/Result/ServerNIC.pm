package App::Manoc::DB::Result::ServerNIC;

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('server_nic');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },

    serverhw_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },

    macaddr => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 17
    },

);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint( [ 'serverhw_id', 'macaddr' ] );

__PACKAGE__->belongs_to(
    serverhw => 'App::Manoc::DB::Result::ServerHW',
    { 'foreign.id' => 'self.serverhw_id' }
);

=head1 NAME

App::Manoc::DB::Result::ServerNIC - Server additional network interface

=head1 DESCRIPTION

A model object to mantain netwalker configuration for a server.

=cut

1;
