package App::Manoc::Search::Widget::Group;

use Moose::Role;

##VERSION

sub render {
    my ( $self, $ctx ) = @_;

    return $self->render_heading($ctx) . " " . $self->render_items($ctx);
}

sub render_heading {
    my ( $self, $ctx ) = @_;
    return "" if ( @{ $self->items } == 1 );
    return $self->match();
}

sub render_items {
    my ( $self, $ctx ) = @_;

    if ( @{ $self->items } == 1 ) {
        my $item = $self->items->[0];
        return $item->render($ctx);
    }

    my $ret = '<ul>';
    foreach ( @{ $self->items } ) {
        $ret .= '<li>' . $_->render($ctx) . '</li>';
    }
    $ret .= '</ul>';

    return $ret;
}

no Moose::Role;
1;
