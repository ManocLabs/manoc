package App::Manoc::Search::Item::VlanRange;

use Moose;
##VERSION

extends 'App::Manoc::Search::Item';

has '+item_type' => ( default => 'vlanrange' );

has 'id' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;
