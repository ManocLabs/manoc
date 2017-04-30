# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::DB::Result::IfNotes;

use parent 'App::Manoc::DB::Result';

use strict;
use warnings;

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

# __PACKAGE__->set_sql('unused',
# 		     q{
# 			 SELECT device AS d, interface AS i
# 			 FROM __TABLE__
# 			 WHERE device=?
# 			   AND (SELECT COUNT(interface)
# 			        FROM mat
# 			        WHERE device=d
# 			         AND interface=i
# 				 AND lastseen > ?) = 0
# 		     });
