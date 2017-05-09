package App::Manoc::DB::Result::MngUrlFormat;
#ABSTRACT: A model object for URL string models

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('mng_url_fmt');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    name => {
        data_type => 'varchar',
        size      => '32',
    },
    format => {
        data_type => 'varchar',
        size      => '255',
    }
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [qw/name/] );

__PACKAGE__->source_info( { "mysql_table_type" => 'InnoDB', } );

1;
