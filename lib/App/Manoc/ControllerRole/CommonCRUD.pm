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

with 'App::Manoc::ControllerRole::ResultSet',
    'App::Manoc::ControllerRole::ObjectForm',
    'App::Manoc::ControllerRole::ObjectList';

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

# can override form_class during object creation
has 'create_form_class' => (
    is  => 'rw',
    isa => 'ClassName'
);

# can override form_class during object editing
has 'edit_form_class' => (
    is  => 'rw',
    isa => 'ClassName'
);

has 'enable_permission_check' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has 'view_object_perm' => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    default => 'view',
);

has 'create_object_perm' => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    default => 'create',
);

has 'edit_object_perm' => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    default => 'edit',
);

has 'delete_object_perm' => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    default => 'delete',
);

=action create

Create a new object using a form. Chained to base.

=cut

sub create : Chained('base') : PathPart('create') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{resultset}->new_result( {} );

    if ( $self->enable_permission_check && $self->create_object_perm ) {
        $c->require_permission( $object, $self->create_object_perm );
    }

    $c->stash(
        object   => $object,
        title    => $self->create_page_title,
        template => $self->create_page_template,
    );

    $self->create_form_class and
        $c->stash( form_class => $self->create_form_class );
    $c->detach('form');
}

=action list

Display a list of items.

=cut

sub list : Chained('object_list') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    if ( $self->enable_permission_check && $self->view_object_perm ) {
        $c->require_permission( $c->stash->{resultset}, $self->view_object_perm );
    }

    $c->stash(
        title    => $self->list_page_title,
        template => $self->list_page_template
    );
}

=action view

Display a single items.

=cut

sub view : Chained('object') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};
    if ( $self->enable_permission_check && $self->view_object_perm ) {
        $c->require_permission( $object, $self->view_object_perm );
    }

    $c->stash(
        title    => $self->view_page_title,
        template => $self->view_page_template
    );
}

=action edit

Use a form to edit a row.

=cut

sub edit : Chained('object') : PathPart('update') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};
    if ( $self->enable_permission_check && $self->edit_object_perm ) {
        $c->require_permission( $object, $self->edit_object_perm );
    }

    $c->stash(
        title      => $self->edit_page_title,
        template   => $self->edit_page_template,
        form_class => $self->edit_form_class,
    );
    $c->detach('form');
}

=action delete

=cut

sub delete : Chained('object') : PathPart('delete') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};
    if ( $self->enable_permission_check && $self->delete_object_perm ) {
        $c->require_permission( $object, $self->delete_object_perm );
    }

    if ( $c->req->method eq 'POST' ) {
        if ( $self->delete_object($c) ) {
            $c->flash( message => $self->object_deleted_message );
            $c->res->redirect( $self->get_delete_success_url($c) );
            $c->detach();
        }
        else {
            $c->res->redirect( $self->get_delete_failure_url($c) );
            $c->detach();
        }
    }

    # show confirm page
    $c->stash(
        title    => $self->delete_page_title,
        template => $self->delete_page_template,
    );
}

=method delete_object

Delete the object using its C<delete> method.

=cut

sub delete_object {
    my ( $self, $c ) = @_;

    return $c->stash->{object}->delete;
}

=method get_delete_failure_url

Default is the view action in current namespace.

=cut

sub get_delete_failure_url {
    my ( $self, $c ) = @_;

    my $action = $c->namespace . "/view";
    return $c->uri_for_action( $action, [ $c->stash->{object_pk} ] );
}

=method get_delete_success_url

Default is the list action in current namespace.

=cut

sub get_delete_success_url {
    my ( $self, $c ) = @_;

    return $c->uri_for_action( $c->namespace . "/list" );
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End: