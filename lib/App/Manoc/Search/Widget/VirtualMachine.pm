package App::Manoc::Search::Widget::VirtualMachine;

use Moose::Role;

##VERSION

sub render {
    my ( $self, $ctx ) = @_;

    my $url = $ctx->uri_for_action( 'virtualmachine/view', [ $self->id ] );
    return "<a href=\"$url\">" . $self->name . "</a>";
}

no Moose::Role;
1;
