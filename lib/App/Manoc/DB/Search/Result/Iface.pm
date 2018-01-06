package App::Manoc::DB::Search::Result::Iface;
#ABSTRACT: Device interface search result

use Moose;

##VERSION

extends 'App::Manoc::DB::Search::Result::Item';

has 'interface' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
        my $args   = $_[0];
        my $iface  = $args->{interface};

        my $device = $iface->device;

        if ( $device && $iface ) {
            $args->{match} ||= $device->name . '/' . $iface;
        }
        return $class->$orig($args);
    }

    return $class->$orig(@_);
};

no Moose;
__PACKAGE__->meta->make_immutable;
