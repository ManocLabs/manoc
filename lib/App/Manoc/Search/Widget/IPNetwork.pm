package App::Manoc::Search::Widget::IPNetwork;

use Moose::Role;

##VERSION

sub render {
    my ( $self, $ctx ) = @_;

    my $url = $ctx->uri_for_action( 'ipnetwork/view', [ $self->id ] );
    return "<a href=\"$url\">" . $self->name . '</a> ' . $self->network;
}

no Moose::Role;
1;
