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
    is  => 'ro',
    isa => 'Str',
);

has 'mng_url' => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);

has 'notes' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    required => 0,

);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
        my $args   = $_[0];
        my $device = $args->{device};
        if ($device) {
            $args->{id}    = $device->id;
            $args->{name}  = $device->name || '';
            $args->{notes} = $device->notes;
            $args->{match} ||= $device->name;
            $args->{mng_url} = $device->get_mng_url;

        }
        return $class->$orig($args);
    }

    return $class->$orig(@_);
};

sub render {
    my ( $self, $ctx ) = @_;

    my $url = $ctx->uri_for_action( 'device/view', [ $self->id ] );
    return '<a href="$url">' . $self->name . "</a>";
}

no Moose;
__PACKAGE__->meta->make_immutable;
