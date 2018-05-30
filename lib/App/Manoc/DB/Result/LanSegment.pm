package App::Manoc::DB::Result::LanSegment;
#ABSTRACT:  A model object representing a LAN Segment

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('lan_segments');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    name => {
        data_type   => 'varchar',
        size        => 64,
        is_nullable => 0
    },
    vtp_domain => {
        data_type   => 'varchar',
        size        => 64,
        is_nullable => 1
    },
    notes => {
        data_type   => 'text',
        is_nullable => 1,
    },
);
__PACKAGE__->set_primary_key(qw(id));
__PACKAGE__->add_unique_constraint( ['name'] );

__PACKAGE__->has_many(
    vlans => 'App::Manoc::DB::Result::Vlan',
    'lan_segment_id',
    { cascade_delete => 0 }
);

__PACKAGE__->has_many(
    vlan_ranges => 'App::Manoc::DB::Result::VlanRange',
    'lan_segment_id',
    { cascade_delete => 0 }
);

__PACKAGE__->has_many(
    devices => 'App::Manoc::DB::Result::Device',
    'lan_segment_id',
    { cascade_delete => 0 }
);

1;
