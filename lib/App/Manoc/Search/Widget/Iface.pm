package App::Manoc::Search::Widget::Iface;

use Moose::Role;

##VERSION

sub render {
    my ( $self, $ctx ) = @_;

    my $url = $ctx->uri_for_action( '/interface/view', [ $self->device_id, $self->interface ] );
    return "<a href=\"$url\">" . $self->device_name . '/' . $self->interface . '</a>';
}

no Moose::Role;
1;
