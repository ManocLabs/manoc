package App::Manoc::DB::Result::SSIDList;

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('ssid_list');

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
    'ssid' => {
        data_type   => 'varchar',
        size        => 128,
        is_nullable => 0,
    },
    'broadcast' => {
        data_type     => 'int',
        is_nullable   => 1,
        default_value => 'NULL'
    },
    'channel' => {
        data_type     => 'int',
        is_nullable   => 1,
        default_value => 'NULL'
    },
);

__PACKAGE__->belongs_to( device => 'App::Manoc::DB::Result::Device', 'device_id' );
__PACKAGE__->set_primary_key( 'device_id', 'interface', 'ssid' );

1;
