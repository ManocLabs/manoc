# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Item::Device;
use Moose;

extends 'Manoc::Search::Item';

has '+item_type' => ( default => 'device' );

has 'id' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'mng_url' => (
    is     => 'ro',
    isa    => 'Str',
    reader => 'get_mng_url',
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
        my $args = $_[0];
        my $b    = $args->{device};
        if ($b) {
            $args->{id}   = $b->id->address;
            $args->{name} = $b->name;
            $args->{match} ||= $b->name;
            $b->get_mng_url and
                $args->{mng_url} = $b->get_mng_url;
        }
        return $class->$orig($args);
    }

    return $class->$orig(@_);
};

no Moose;
__PACKAGE__->meta->make_immutable;
