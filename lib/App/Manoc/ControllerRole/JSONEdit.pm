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

    $c->forward('object_form_create');
    $c->forward('prepare_form_json_response');
}

=action edit_js

=cut

sub edit_js : Chained('object') : PathPart('edit/js') : Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('object_form_edit');
    $c->forward('prepare_form_json_response');
}

=action delete_js

=cut

sub delete_js : Chained('object') : PathPart('delete/js') : Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('object_form_delete');

    my $success = $c->stash->{form_delete_success};

    my $json_data = {};
    $json_data->{form_ok} = $success;
    if ( !$success ) {
        $json_data->{errors} = $c->stash->{form_delete_error} || "";
    }
    $c->stash( current_view => 'JSON' );
    $c->stash( json_data    => $json_data );
}

=method prepare_form_json_response

=cut

sub prepare_form_json_response : Private {
    my ( $self, $c ) = @_;

    my $form           = $c->stash->{form};
    my $process_status = $form->is_valid;

    my $json_data = {};
    $json_data->{form_ok} = $process_status ? 1 : 0;
    if ( !$process_status ) {
        $json_data->{errors} = $form->form_errors || "";
        $json_data->{field_errors} = [ $form->errors_by_name, ];
    }
    $c->stash( current_view => 'JSON' );
    $c->stash( json_data    => $json_data );
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
