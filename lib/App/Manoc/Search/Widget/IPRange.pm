package App::Manoc::Search::Widget::IPRange;

use Moose::Role;

##VERSION

sub render {
    my ( $self, $ctx );

    my $url = $ctx->uri_for_action( 'ipnetwork/view', [ $self->id ] );
    return "<a href=\"$url\">" . $self->name . '</a> ';
}

no Moose::Role;
1;
