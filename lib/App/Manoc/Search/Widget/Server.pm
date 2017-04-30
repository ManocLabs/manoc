# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Search::Widget::Server;
use Moose::Role;

sub render {
    my ( $self, $ctx ) = @_;

    my $url = $ctx->uri_for_action( 'server/view', [ $self->id ] );
    return "<a href=\"$url\">" . $self->hostname . "</a>";
}

no Moose::Role;
1;
