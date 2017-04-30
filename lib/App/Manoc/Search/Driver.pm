package App::Manoc::Search::Driver;

use Moose;

##VERSION

has engine => ( is => 'ro' );

no Moose;
__PACKAGE__->meta->make_immutable;
