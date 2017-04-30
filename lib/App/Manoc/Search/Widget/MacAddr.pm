package App::Manoc::Search::Widget::MacAddr;

use Moose::Role;

##VERSION

with 'App::Manoc::Search::Widget::Group' => { -exclude => ['render_heading'] };

sub render_heading {
    my ( $self, $ctx ) = @_;

    my $url = $ctx->uri_for_action( '/mac/view', [ $self->addr ] );
    return "<a href=\"$url\">" . $self->addr . '</a>';
}

no Moose::Role;
1;
