package App::Manoc::DB::Result::IfNotes;
#ABSTRACT: A model object for user notes on device interfaces

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('if_notes');

__PACKAGE__->add_columns(
    'device_id' => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    'interface' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64
    },
    'notes' => {
        data_type   => 'text',
        is_nullable => 0,
    },
);

__PACKAGE__->belongs_to( device => 'App::Manoc::DB::Result::Device', 'device_id' );
__PACKAGE__->set_primary_key( 'device_id', 'interface' );
1;
