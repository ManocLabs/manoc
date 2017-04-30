package App::Manoc::Search::Widget::VlanRange;

use Moose::Role;

##VERSION

sub render {
    my ( $self, $ctx ) = @_;

    my $url = $ctx->uri_for_action( '/vlanrange/view', [ $self->id ] );
    return "VLAN range <a href=\"$url\">" . $self->name . '</a>';
}

no Moose::Role;
1;
