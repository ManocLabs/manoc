package App::Manoc::Search::Widget::Rack;

use Moose::Role;

##VERSION

sub render {
    my ( $self, $ctx ) = @_;

    my $url = $ctx->uri_for_action( '/rack/view', [ $self->id ] );
    return "<a href=\"$url\">" . $self->name . '</a>';
}

no Moose::Role;
1;
