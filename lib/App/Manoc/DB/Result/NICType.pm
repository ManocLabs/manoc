package App::Manoc::DB::Result::NICType;
#ABSTRACT: A model object for server additional network interfaces

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('nic_types');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_nullable       => 0,
        is_auto_increment => 1,
    },

    name => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 32
    },

);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints( ['name'] );

__PACKAGE__->has_many(
    server_hw_nics => 'App::Manoc::DB::Result::ServerHWNIC',
    'nic_type_id'
);

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
