package App::Manoc::ControllerBase::APIv1CRUD;
#ABSTRACT: Base class for API controllers

use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends 'App::Manoc::ControllerBase::APIv1'; }

with
    'App::Manoc::ControllerRole::ResultSet',
    'App::Manoc::ControllerRole::ObjectForm',
    'App::Manoc::ControllerRole::ObjectList',
    'App::Manoc::ControllerRole::ObjectSerializer',
    'App::Manoc::ControllerRole::JSONView';

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            Chained => 'deserialize',
        }
    },
    class      => 'ManocDB::Building',
    form_class => 'App::Manoc::Form::Building',
);

=head1 DESCRIPTION

This class can be used as a base for controllers using the L<App::Manoc::ControllerRole::CommonCRUD> role.

=cut

=action list

GET api/v1/<namespace>

=cut

sub list : Chained('object_list') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    $c->forward("object_list_js");
}

=action view

GET api/v1/<namespace>/<id>

=cut

sub view : Chained('object') : PathPart('') : Args(0) {
    my ( $self, $c, $id ) = @_;

    $c->forward('object_view_js');
}

=action create

POST api/v1/<namespace>/create

=cut

sub create : Chained('base') PathPart('') Args(0) POST {
    my ( $self, $c ) = @_;

    $c->forward("object_form_create");
    $c->forward("api_form");
}

=action update

POST api/v1/<namespace>/<id>

=cut

sub update : Chained('object') PathPart('') Args(0) POST {
    my ( $self, $c ) = @_;

    $c->forward("object_form_edit");
    $c->forward("api_form");
}

=for Pod::Coverage  api_form

=cut

sub api_form : Private {
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};

    if ( $form->is_valid ) {
        $c->stash->{api_response_data} = {
            object_id => $form->item_id,
            status    => 'success',
        };
    }
    else {
        $c->stash(
            api_field_errors => {
                errors => $form->form_errors || "",
                field_errors => [ $form->errors_by_name, ],
            }
        );
    }
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
