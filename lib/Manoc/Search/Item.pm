# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Item;
use Moose;

has 'item_type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

# unixtime
has 'timestamp' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);

has 'match' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'key' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_key',
);

has 'text' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

sub _build_key { return $_[0]->match }

no Moose;
__PACKAGE__->meta->make_immutable;
