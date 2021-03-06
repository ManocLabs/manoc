package App::Manoc::DB::Result::Building;
#ABSTRACT: A model object for buildings

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->table('buildings');
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
    description => {
        data_type => 'varchar',
        size      => '255',
    },
    notes => {
        data_type   => 'text',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [qw/name/] );

__PACKAGE__->has_many(
    racks => 'App::Manoc::DB::Result::Rack',
    'building_id', { cascade_delete => 0 }
);

__PACKAGE__->has_many(
    warehouses => 'App::Manoc::DB::Result::Warehouse',
    'building_id', { cascade_delete => 0 }
);

=method label

Return a string describing the object

=cut

sub label {
    my $self  = shift;
    my $label = $self->name;
    $self->description and $label .= " (" . $self->description . ")";
    return $label;
}

1;
