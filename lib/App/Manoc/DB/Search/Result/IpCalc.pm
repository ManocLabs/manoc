package App::Manoc::DB::Search::Result::IpCalc;
#ABSRTACT: IP Calculator search result

use Moose;

##VERSION

extends 'App::Manoc::DB::Search::Result::Item';

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
