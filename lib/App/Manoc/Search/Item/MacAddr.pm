package App::Manoc::Search::Item::MacAddr;

use Moose;

##VERSION

extends 'App::Manoc::Search::Item::Group';

has '+item_type' => ( default => 'macaddr' );

has addr => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_addr { $_[0]->match }

no Moose;
__PACKAGE__->meta->make_immutable;
