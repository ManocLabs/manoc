package App::Manoc::ControllerRole::JSONEdit;
#ABSTRACT: Role for adding JSON support for object edit and creation

use Moose::Role;
##VERSION

use namespace::autoclean;

use MooseX::MethodAttributes::Role;

requires 'base', 'object';

=action create_js

=cut

sub create_js : Chained('base') : PathPart('create/js') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( current_view => 'JSON' );

    $c->forward('object_form_create');
}

=action edit_js

=cut

sub edit_js : Chained('object') : PathPart('edit/js') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( current_view => 'JSON' );

    $c->forward('object_form_edit');
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
