# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Item::VlanRange;
use Moose;

extends 'Manoc::Search::Item';

has '+item_type' => ( default => 'vlanrange' );

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;
