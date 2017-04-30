package App::Manoc::Form::Widget::Repeatable;

use Moose::Role;

##VERSION

with 'HTML::FormHandler::Widget::Field::Repeatable';

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args;
    if ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
        $args = shift;
    }
    else {
        $args = {@_};
    }

    $args->{do_wrapper}    = 0;
    $args->{num_extra}     = 0;
    $args->{init_contains} = { do_wrapper => 0, };

    $args->{wrap_repeatable_element_method} = \&wrap_repeatable_element;

    return $class->$orig(%$args);
};

sub build_tags {
    my $self = shift;
    my $id   = $self->id;
    return {
        before_element => "<div id=\"$id\">",
        after_element  => '</div>'
    };
}

sub wrap_repeatable_element {
    my ( $self, $output, $name ) = @_;
    my $id = $self->id;

    return "<div class=\"form-group hfh-repinst\" id=\"$id.$name\">$output" .
        "<div data-rep-id=\"$id\" class=\"btn btn-success form-btn-add\">" .
        "<span class=\"glyphicon glyphicon-plus\"></span>" . "</div>" . "</div>";
}

no Moose::Role;

use namespace::autoclean;
1;
