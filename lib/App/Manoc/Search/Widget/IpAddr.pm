package App::Manoc::Search::Widget::IpAddr;

use Moose::Role;

##VERSION

with 'App::Manoc::Search::Widget::Group' => { -exclude => ['render_heading'] };

sub render_heading {
    my ( $self, $ctx ) = @_;

    my $url = $ctx->uri_for_action( '/ip/view', [ $self->addr ] );
    return "<a href=\"$url\">" . $self->addr . "</a>";
}

no Moose::Role;
1;
