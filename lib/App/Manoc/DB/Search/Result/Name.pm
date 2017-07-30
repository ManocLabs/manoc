package App::Manoc::DB::Search::Result::Name;
#ABSTRACT:  Mac address search result

use Moose;

##VERSION

extends 'App::Manoc::DB::Search::Result::Item';
with 'App::Manoc::DB::Search::Result::Group';

no Moose;
__PACKAGE__->meta->make_immutable;
