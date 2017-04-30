package App::Manoc::DB::Result::Oui;

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('oui');

# prefix must be lowercase!

__PACKAGE__->add_columns(
    'prefix' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 8
    },
    'vendor' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64
    },
);

__PACKAGE__->set_primary_key('prefix');

1;
