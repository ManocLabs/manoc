# Copyright 2017 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::DB::Result::WorkstationSWPkg;

use strict;
use warnings;

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('workstation_swpkg');
__PACKAGE__->add_columns(
    workstation_id => {
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

__PACKAGE__->set_primary_key(qw/workstation_id software_pkg_id/);

__PACKAGE__->belongs_to(
    workstation => 'App::Manoc::DB::Result::Workstation',
    'workstation_id'
);

__PACKAGE__->belongs_to(
    software_pkg => 'App::Manoc::DB::Result::SoftwarePkg',
    'software_pkg_id'
);

=head1 NAME

App::Manoc::DB::Result::WorkstationSWPkg - A model object representing the JOIN
between Software and Workstation.

=head1 DESCRIPTION

This is an object that represents a mapping between workstations and
softwarepkg in the application database.  It uses DBIx::Class (aka,
DBIC) to do ORM.

=cut

1;
