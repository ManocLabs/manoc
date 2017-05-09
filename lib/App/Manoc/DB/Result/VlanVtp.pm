package App::Manoc::DB::Result::VlanVtp;
#ABSTRACT: A model object representing a VTP info

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('vlan_vtp');

__PACKAGE__->add_columns(
    id => {
        data_type   => 'int',
        is_nullable => 0
    },
    name => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0
    }
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    vlan => 'App::Manoc::DB::Result::Vlan',
    { 'foreign.id' => 'self.id' },
    {
        join_type                 => 'LEFT',
        is_foreign_key_constraint => 0,
    }
);

1;
