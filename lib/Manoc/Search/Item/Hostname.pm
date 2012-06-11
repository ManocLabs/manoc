# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Item::Hostname;
use  Manoc::IpAddress;
use Moose;

extends 'Manoc::Search::Item';

has '+item_type' => ( default => 'hostname' );

has 'ipaddr' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
        my $args = $_[0];
        my $b    = $args->{hostname};
        if ($b) {
            $args->{ipaddr} = $b->ipaddr->address;
            $args->{name}   = $b->name;
            $args->{match} ||= $b->name;
        }
        return $class->$orig($args);
    }

    return $class->$orig(@_);
};

no Moose;
__PACKAGE__->meta->make_immutable;
