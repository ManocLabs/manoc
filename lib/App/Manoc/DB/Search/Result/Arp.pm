package App::Manoc::DB::Search::Result::Arp;
#ABSTRACT: ARP search result

use Moose;

##VERSION

extends 'App::Manoc::DB::Search::Result::Item';

has ipaddress => (
    is       => 'ro',
    isa      => 'App::Manoc::IPAddress::IPv4',
    required => 1,
);

has macaddress => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;
