package App::Manoc::Search::Widget::Vlan;

use Moose::Role;

##VERSION

sub render {
    my ( $self, $ctx ) = @_;

    my $url = $ctx->uri_for_action( '/vlan/view', [ $self->id ] );
    return "VLAN <a href=\"$url\">" . $self->name . '</a>';
}

no Moose::Role;
1;
