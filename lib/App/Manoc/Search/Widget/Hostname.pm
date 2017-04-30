package App::Manoc::Search::Widget::Hostname;

use Moose::Role;

##VERSION

sub render {
    my ( $self, $ctx ) = @_;

    my $url = $ctx->uri_for_action( '/ip/view', [ $self->ipaddr ] );
    return "<a href=\"$url\">" . $self->ipaddr . "</a>";
}

no Moose::Role;
1;
