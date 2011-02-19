# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Session;

use base qw(DBIx::Class);

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('sessions');
__PACKAGE__->add_columns(
    'id' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 72,
    },
    'session_data' => { data_type => 'text', },
    'expires'      => {
        data_type => 'int',
        size      => 10,
    }
);

__PACKAGE__->set_primary_key(qw(id));

=head1 NAME

Manoc::DB::Result::Session - A model object representing a WEB UI session

=head1 DESCRIPTION

Needed for L<CGI::Session> L<CGI::Session::Driver::dbixc>

=cut

1;
