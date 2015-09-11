# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Item::Iface;
use Moose;

extends 'Manoc::Search::Item';

has '+item_type' => ( default => 'iface' );

has 'interface' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'device_id' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'device_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
	my $args = $_[0];
	my $device = delete $args->{device};
	if ($device) {
	    $args->{device_id}   = $device->id;
	    $args->{device_name} = $device->name;
	}
	return $class->$orig($args);
    }

    return $class->$orig(@_);
};

no Moose;
__PACKAGE__->meta->make_immutable;
