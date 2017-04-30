package App::Manoc::Search::Item::IPRange;

use Moose;

##VERSION

extends 'App::Manoc::Search::Item';

has '+item_type' => ( default => 'iprange' );

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
