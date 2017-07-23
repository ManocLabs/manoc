package App::Manoc::DB::Search::Result::MacAddr;
#ABSTRACT:  Mac address search result

use Moose;

##VERSION

extends 'App::Manoc::DB::Search::Result::Item';
with 'App::Manoc::DB::Search::Result::Group';

has address => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
    builder    => '_build_address'
);

sub _build_address { $_[0]->match }

no Moose;
__PACKAGE__->meta->make_immutable;
