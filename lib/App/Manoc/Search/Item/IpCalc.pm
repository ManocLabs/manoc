package App::Manoc::Search::Item::IpCalc;

use Moose;

##VERSION

extends 'App::Manoc::Search::Item';

has '+item_type' => ( default => 'ipcalc' );

has 'address' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'prefix' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;
