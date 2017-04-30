# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Search::Widget::HWAsset;
use Moose::Role;

sub render {
    my ( $self, $ctx ) = @_;

    my $url       = $ctx->uri_for_action( 'hwasset/view', [ $self->id ] );
    my $inventory = $self->inventory;
    my $model     = $self->model;
    my $vendor    = $self->vendor;
    return "<a href=\"$url\">$inventory - $vendor $model</a>";
}

no Moose::Role;
1;
