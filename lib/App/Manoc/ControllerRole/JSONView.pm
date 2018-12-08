package App::Manoc::ControllerRole::JSONView;
#ABSTRACT: Role for adding JSON support for view and view list

use Moose::Role;
##VERSION

use namespace::autoclean;

use MooseX::MethodAttributes::Role;

requires 'serialize_objects';

=method prepare_json_object

Call serialize_object. Redefine this method for custom serialization.

=cut

sub prepare_json_object {
    my ( $self, $c, $row ) = @_;
    return $self->serialize_object( $c, $row );
}

=method prepare_json_objects

Call serialize_objects. Redefine this method for custom serialization.

=cut

sub prepare_json_objects {
    my ( $self, $c, $rows ) = @_;
    return $self->serialize_objects( $c, $rows );
}

=method object_view_js

=cut

sub object_view_js : Private {
    my ( $self, $c ) = @_;

    $c->stash(
        json_data    => $self->prepare_json_object( $c, $c->stash->{object} ),
        current_view => 'JSON'
    );
}

=method object_list_js

=cut

sub object_list_js : Private {
    my ( $self, $c ) = @_;

    $c->stash(
        json_data    => $self->prepare_json_objects( $c, $c->stash->{object_list} ),
        current_view => 'JSON'
    );
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
