package App::Manoc::Search::Widget::Building;

use Moose::Role;

##VERSION

sub render {
    my ( $self, $ctx ) = @_;

    my $url = $ctx->uri_for_action( 'building/view', [ $self->id ] );
    return "<a href=\"$url\">" . $self->name . "</a> " . $self->description;
}

no Moose::Role;
1;
