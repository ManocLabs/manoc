package App::Manoc::Controller::NICType;
#ABSTRACT: MngUrlFormat controller

use Moose;

##VERSION

use namespace::autoclean;

use App::Manoc::Form::NICType;

BEGIN { extends 'App::Manoc::ControllerBase::CRUD'; }

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'nictype',
        }
    },
    class            => 'ManocDB::NICType',
    form_class       => 'App::Manoc::Form::NICType',
    view_object_perm => undef,
);

=action view

Redirect to edit

=cut

sub view : Chained('object') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};
    $c->response->redirect( $c->uri_for_action( $c->namespace . "/edit", [ $object->id ] ) );
}

=method delete_object

=cut

sub delete_object {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};
    if ( $object->server_hw_nics->count > 0 ) {
        $c->flash( error_msg => 'NIC type is in use. Cannot be deleted.' );
        return;
    }

    return $c->stash->{'object'}->delete;
}

=method get_delete_failure_url

=cut

sub get_delete_failure_url {
    my ( $self, $c ) = @_;

    my $action = $c->namespace . "/list";
    return $c->uri_for_action($action);
}

=action get_form_success_url

=cut

sub get_form_success_url {
    my ( $self, $c ) = @_;

    my $action = $c->namespace . "/list";
    return $c->uri_for_action($action);
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
