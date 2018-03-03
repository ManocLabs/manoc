package App::Manoc::Controller::MngUrlFormat;
#ABSTRACT: MngUrlFormat controller

use Moose;

##VERSION

use namespace::autoclean;

use App::Manoc::Form::MngUrlFormat;

BEGIN { extends 'Catalyst::Controller'; }
with "App::Manoc::ControllerRole::CommonCRUD" => { -excludes => 'view' };

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'mngurlformat',
        }
    },
    class                   => 'ManocDB::MngUrlFormat',
    form_class              => 'App::Manoc::Form::MngUrlFormat',
    enable_permission_check => 1,
    view_object_perm        => undef,

);

=method delete_object

=cut

sub delete_object {
    my ( $self, $c ) = @_;

    my $id = $c->stash->{object_pk};
    if ( $c->model('ManocDB::Device')->search( { mng_url_format => $id } )->count ) {
        $c->flash( error_msg => 'Format is in use. Cannot be deleted.' );
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
