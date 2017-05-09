package App::Manoc::DB::Result::WorkstationSWPkg;
#ABSTRACT:  A model object representing the JOIN between SoftwarePkg and Workstation.

use strict;
use warnings;

##VERSION

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

1;
