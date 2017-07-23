package App::Manoc::DB::Search::Result::Row;

use Moose;

##VERSION

extends 'App::Manoc::DB::Search::Result::Item';

has 'row' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;
