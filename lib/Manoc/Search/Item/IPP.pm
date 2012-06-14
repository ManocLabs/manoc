# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Item::IPP;
use Moose;

extends 'Manoc::Search::Item::Group';

has '+item_type' => ( default => 'ipp' );

has 'device' => (
    is     => 'ro',
    isa    => 'Str',
    required => 0,
);

has 'iface' => (
    is     => 'ro',
    isa    => 'Str',
    required => 0,
);

no Moose;
__PACKAGE__->meta->make_immutable;
