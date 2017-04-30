package App::Manoc::Search::Widget::Server;

use Moose::Role;

##VERSION

sub render {
    my ( $self, $ctx ) = @_;

    my $url = $ctx->uri_for_action( 'server/view', [ $self->id ] );
    return "<a href=\"$url\">" . $self->hostname . "</a>";
}

no Moose::Role;
1;
