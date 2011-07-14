# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::MngUrlFormat;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('mng_url_fmt');

__PACKAGE__->add_columns(
    id => {
        data_type   => 'int',
        is_nullable => 0,
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
