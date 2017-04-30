package App::Manoc::Search::Widget::HWAsset;

use Moose::Role;

##VERSION

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
