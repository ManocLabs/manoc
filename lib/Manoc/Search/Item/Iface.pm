# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Item::Iface;
use Moose;

extends 'Manoc::Search::Item::Device';

has '+item_type' => ( default => 'iface' );

has 'interface' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'device' => (
    is       => 'ro',
    required => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;
