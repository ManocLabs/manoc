# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Search::Item::IPNetwork;
use Moose;

extends 'App::Manoc::Search::Item';

has '+item_type' => ( default => 'ipnetwork' );

has 'id' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'network' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;
