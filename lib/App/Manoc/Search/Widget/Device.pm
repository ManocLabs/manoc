package App::Manoc::Search::Widget::Device;

use Moose::Role;

##VERSION

sub render {
    my ( $self, $ctx ) = @_;

    my $url = $ctx->uri_for_action( 'device/view', [ $self->id ] );
    return "<a href=\"$url\">" . $self->name . "</a>";
}

no Moose::Role;
1;
