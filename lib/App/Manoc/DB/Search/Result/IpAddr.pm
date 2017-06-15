package App::Manoc::DB::Search::Result::IPAddr;
#ABSTRACT:  IP address search result

use Moose;
use App::Manoc::IPAddress::IPv4;
##VERSION

extends 'App::Manoc::DB::Search::Result::Item';
with 'App::Manoc::DB::Search::Result::Group';

has address => (
    is       => 'ro',
    isa      => 'App::Manoc::IPAddress::IPv4',
    required => 1,
);

override _build_key => sub {
    shift->address->padded;
};

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
        my $args = $_[0];
        my $addr = $args->{address} // $args->{match};

        ref($addr) or
            $args->{address} = App::Manoc::IPAddress::IPv4->new($addr);
        return $class->$orig($args);
    }

    return $class->$orig(@_);
};

no Moose;
__PACKAGE__->meta->make_immutable;
