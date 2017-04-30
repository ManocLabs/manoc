# Copyright 2017 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::DB::Result::ServerSWPkg;

use parent 'App::Manoc::DB::Result';

use strict;
use warnings;

__PACKAGE__->table('server_swpkg');
__PACKAGE__->add_columns(
    server_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    software_pkg_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    version => {
        data_type      => 'varchar',
        size           => 255,
        is_foreign_key => 1,
        is_nullable    => 1,
    },
);

__PACKAGE__->set_primary_key(qw/server_id software_pkg_id/);

__PACKAGE__->belongs_to(
    server => 'App::Manoc::DB::Result::Server',
    'server_id'
);

__PACKAGE__->belongs_to(
    software_pkg => 'App::Manoc::DB::Result::SoftwarePkg',
    'software_pkg_id'
);

=head1 NAME

App::Manoc::DB::Result::ServerSWPkg - A model object representing the JOIN
between Software and Server.

=head1 DESCRIPTION

This is an object that represents a mapping between servers and
softwarepkg in the application database.  It uses DBIx::Class (aka,
DBIC) to do ORM.

=cut

1;
