# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Item::Server;
use Moose;

extends 'Manoc::Search::Item';

has '+item_type' => ( default => 'server' );

has 'id' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'hostname' => (
    is  => 'ro',
    isa => 'Str',
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
        my $args   = $_[0];
        my $server = $args->{server};
        if ($server) {
            $args->{id} = $server->id;
            $args->{hostname} = $server->hostname || '';
            $args->{match} ||= $server->hostname;

        }
        return $class->$orig($args);
    }

    return $class->$orig(@_);
};

no Moose;
__PACKAGE__->meta->make_immutable;
