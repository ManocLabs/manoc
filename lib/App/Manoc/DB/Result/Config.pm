package App::Manoc::DB::Result::Config;

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('config');

__PACKAGE__->add_columns(
    'name' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64
    },
    'value' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 255
    },
);

__PACKAGE__->set_primary_key('name');

1;
