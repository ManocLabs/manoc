package App::Manoc::ControllerRole::CommonCRUD;
#ABSTRACT: Controller role for Manoc CRUD

use Moose::Role;

##VERSION

use MooseX::MethodAttributes::Role;
use namespace::autoclean;

=head1 DESCRIPTION

Catalyst controller role for Manoc common CRUD implementation.

=head1 SYNPOSYS

  package App::Manoc::Controller::Artist;

  use Moose;
  extends "Catalyst::Controller";
  with "App::Manoc::ControllerRole::CommonCRUD";

  __PACKAGE__->config(
      # define PathPart
      action => {
          setup => {
              PathPart => 'artist',
          }
      },
      class      => 'ManocDB::Artist',
      form_class => 'App::Manoc::Form::Artist',

   );

  __PACKAGE__->meta->make_immutable;
  no Moose;
  1;

=head1 ROLES CONSUMED

=for :list

* App::Manoc::ControllerRole::ResultSet
* App::Manoc::ControllerRole::ObjectForm
* App::Manoc::ControllerRole::ObjectList

=cut

with
    'App::Manoc::ControllerRole::ResultSet',
    'App::Manoc::ControllerRole::ObjectForm',
    'App::Manoc::ControllerRole::ObjectList',
    'App::Manoc::ControllerRole::ObjectSerializer',
    'App::Manoc::ControllerRole::JSONView',
    'App::Manoc::ControllerRole::JSONEdit',
    'App::Manoc::ControllerRole::CSVView';

has 'create_page_title' => ( is => 'rw', isa => 'Str' );
has 'view_page_title'   => ( is => 'rw', isa => 'Str' );
has 'edit_page_title'   => ( is => 'rw', isa => 'Str' );
has 'delete_page_title' => ( is => 'rw', isa => 'Str' );
has 'list_page_title'   => ( is => 'rw', isa => 'Str' );

has 'create_page_template' => (
    is  => 'rw',
    isa => 'Str'
);

has 'view_page_template' => (
    is  => 'rw',
    isa => 'Str'
);

has 'edit_page_template' => (
    is  => 'rw',
    isa => 'Str'
);

has 'delete_page_template' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'generic_delete.tt'
);

has 'list_page_template' => (
    is  => 'rw',
    isa => 'Str'
);

has 'object_deleted_message' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Deleted',
);

=action list

Display a list of items.

=cut

sub list : Chained('object_list') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        title    => $self->list_page_title,
        template => $self->list_page_template
    );
}

=action list_js

=cut

sub list_js : Chained('object_list') : PathPart('js') : Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('object_list_js');
}

=action view

Display a single items.

=cut

sub view : Chained('object') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        title    => $self->view_page_title,
        template => $self->view_page_template
    );
}

=action view_js

=cut

sub view_js : Chained('object') : PathPart('js') : Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('object_view_js');
}

=action create

Create a new object using a form. Chained to base.

=cut

sub create : Chained('base') : PathPart('create') : Args(0) {
    my ( $self, $c ) = @_;

    my $template = $c->stash->{template} ||
        $self->create_page_template ||
        $c->namespace . "/form.tt";

    $c->stash(
        title                     => $self->create_page_title,
        template                  => $template,
        object_form_ajax_add_html => 1,                          # enable manoc ajax forms
    );

    $c->forward('object_form_create');

    if ( $c->stash->{is_xhr} ) {
        $c->forward('object_form_ajax_response');
        return;
    }

    $c->stash->{form}->is_valid and
        $c->res->redirect( $self->get_form_success_url($c) );
}

=action edit

Use a form to edit a row.

=cut

sub edit : Chained('object') : PathPart('update') : Args(0) {
    my ( $self, $c ) = @_;

    my $template = $c->stash->{template} ||
        $self->edit_page_template ||
        $c->namespace . "/form.tt";

    $c->stash(
        title                => $self->edit_page_title,
        template             => $template,
        ajax_render_template => 1,                        # enable manoc ajax forms
    );

    $c->forward('object_form_edit');

    if ( $c->stash->{is_xhr} ) {
        $c->forward('object_form_ajax_response');
        return;
    }

    $c->stash->{form}->is_valid and
        $c->res->redirect( $self->get_form_success_url($c) );
}

=action delete

=cut

sub delete : Chained('object') : PathPart('delete') : Args(0) {
    my ( $self, $c ) = @_;

    # show confirm page
    $c->stash(
        title    => $self->delete_page_title,
        template => $self->delete_page_template,
    );

    $c->forward('object_form_delete');

    if ( $c->stash->{is_xhr} ) {
        $c->forward('object_form_delete_ajax_response');
        return;
    }

    if ( $c->stash->{form_delete_posted} ) {
        if ( $c->stash->{form_delete_success} ) {
            $c->flash( message => $self->object_deleted_message );
            $c->res->redirect( $self->get_delete_success_url($c) );
            $c->detach();
        }
        else {
            $c->res->redirect( $self->get_delete_failure_url($c) );
            $c->detach();
        }
    }
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
