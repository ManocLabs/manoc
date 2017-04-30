# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Search::Widget::IpAddr;

use Moose::Role;
with 'App::Manoc::Search::Widget::Group' => { -exclude => ['render_heading'] };

sub render_heading {
    my ( $self, $ctx ) = @_;

    my $url = $ctx->uri_for_action( '/ip/view', [ $self->addr ] );
    return "<a href=\"$url\">" . $self->addr . "</a>";
}

no Moose::Role;
1;
