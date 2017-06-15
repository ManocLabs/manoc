package App::Manoc::DB::Search::Result::Hostname;

use Moose;

##VERSION

use App::Manoc::IPAddress::IPv4;

extends 'App::Manoc::DB::Search::Result::Item';

has 'ipaddress' => (
    is       => 'ro',
    isa      => 'App::Manoc::IPAddress::IPv4',
    required => 1,
);

has 'hostname' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
        my $args = $_[0];
        my $addr = $args->{ipaddress};
        ref($addr) or
            $args->{ipaddress} = App::Manoc::IPAddress::IPv4->new($addr);
        return $class->$orig($args);
    }

    return $class->$orig(@_);
};

no Moose;
__PACKAGE__->meta->make_immutable;
