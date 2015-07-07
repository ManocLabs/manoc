# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::ControllerRole::CommonCRUD;

use Moose::Role;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

requires 'get_form';

=head1 NAME

Manoc::ControllerRole::CommonCRUD - Controller role for Manoc CRUD

=head1 DESCRIPTION

Catalyst controller role for Manoc common CRUD implementation.

=head1 SYNPOSYS

  package Manoc::Controller::Artist;

  use Moose;
  extends "Catalyst::Controller";
  with "Manoc::ControllerRole::CommonCRUD";

  __PACKAGE__->config( 
      # define PathPart
      action => {
          setup => {
              PathPart => 'artist',
          }
      },
      class      => 'ManocDB::Artist',
      );

  sub get_form {
     my ($self, $c) = @_;
     return Manoc::Form::Artist->new();
  }

  __PACKAGE__->meta->make_immutable;
  no Moose;
  1;

=cut

has 'class' => ( is => 'ro', isa => 'Str', writer => '_set_class' );

has 'create_page_title' => ( is => 'rw', isa => 'Str' );
has 'view_page_title' => ( is => 'rw', isa => 'Str' );
has 'edit_page_title'   => ( is => 'rw', isa => 'Str' );
has 'delete_page_title' => ( is => 'rw', isa => 'Str' );
has 'list_page_title'   => ( is => 'rw', isa => 'Str' );

has 'create_page_template' =>  (
     is => 'rw',
     isa => 'Str'
);
has 'view_page_template' =>  (
     is => 'rw',
     isa => 'Str'
);
has 'edit_page_template'   =>  (
    is => 'rw',
    isa => 'Str'
);
has 'delete_page_template' =>  (
    is => 'rw',
    isa => 'Str',
    default => 'generic_delete.tt'
);
has 'list_page_template'   =>  (
    is => 'rw',
    isa => 'Str'
);

has 'object_updated_message' => (
   is => 'rw',
   isa => 'Str',
   default => 'Updated',
);

has 'object_deleted_message' => (
   is => 'rw',
   isa => 'Str',
   default => 'Deleted',
);

=head1 ACTIONS

=head2 setup

=cut

sub setup :
    Chained('/') : CaptureArgs(0) :
    PathPart('specify.in.subclass.config') {}

=head2 base

Add a resultset to the stash. Chained to setup.

=cut

sub base : Chained('setup') : PathPart('') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash( resultset => $self->get_resultset($c) );
}

=head2 create

Create a new object using a form. Chained to base.

=cut

sub create : Chained('base') : PathPart('create') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{resultset}->new_result( {} );
    $c->stash(
        object   => $object,
        title    => $self->create_page_title,
        template => $self->create_page_template,
    );
    $c->detach('form');
}

=head2 object_list
sc
Load the list of objects from the resultset into the stash. Chained to base.
This is the point for chaining all actions using the list of object

=cut

sub object_list : Chained('base') : PathPart('') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( object_list => $self->get_object_list($c) );
}


=head2 list

Disp

=cut

sub list : Chained('object_list') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $c->stash(
        title    => $self->list_page_title,
        template => $self->list_page_template
    );
}


=head2 object

This action is the chain root for all the actions which operate on a single identifer,
e.g. view, edit, delete.

=cut

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash(
        object => $self->get_object($c, $id),
        object_pk => $id
    );
    if ( !$c->stash->{object} ) {
        $c->detach('/error/http_404');
    }
}


sub view : Chained('object') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(
        title    => $self->view_page_title,
        template => $self->view_page_template
    );
}


sub edit : Chained('object') : PathPart('update') : Args(0) {
    my ( $self, $c ) = @_;

    # show confirm page
    $c->stash(
        title    => $self->edit_page_title,
        template => $self->edit_page_template,
    );
    $c->detach('form');
}


sub delete : Chained('object') : PathPart('delete') : Args(0) {
    my ( $self, $c ) = @_;

    if ( lc $c->req->method eq 'post' ) {
        if ( $self->delete_object($c) ) {
            $c->flash( message => $self->object_deleted_message );
            $c->res->redirect( $c->namespace . "/" . $c->uri_for_action('list') );
            $c->detach();
        } else {
            my $action = $c->namespace . "/view";
            $c->res->redirect( $c->uri_for_action( $action,[ $c->stash->{object_pk} ] ));
        }
    }

    # show confirm page
    $c->stash(
        title    => $self->delete_page_title,
        template => $self->delete_page_template,
    );
}

=head2 form

Handle creation and editing of resources.
Form defaults can be injected by form_defaults in stash.

=cut

sub form : Private {
    my ( $self, $c ) = @_;

    my $item = $c->stash->{object};
    my $form = $self->get_form($c);

    $c->stash(
        form   => $form,
        action => $c->uri_for($c->action, $c->req->captures),
    );
    unless ( $c->stash->{template} ) {
        $c->stash(template =>  $c->namespace . "/form.tt" );
    }

    # the "process" call has all the saving logic,
    #   if it returns False, then a validation error happened
    
    my %process_params;
    $process_params{item}   =  $c->stash->{object};
    $process_params{params} =  $c->req->parameters;
    if ( $c->stash->{form_defaults} ) {
        $process_params{defaults} = $c->stash->{form_defaults};
        $process_params{use_defaults_over_obj} = 1;
    }
    return unless $form->process( %process_params );

    $c->stash(message => $self->object_updated_message );
    if ($c->stash->{is_xhr}) {
        $c->stash(no_wrapper => 1);
        $c->stash(template   => 'dialog/message.tt');
        return;
    }

    $c->res->redirect( $c->uri_for($self->action_for('list')) );
    $c->detach();
}

=head1 METHODS

=head2 get_resultset

It returns a resultset of the controller's class.  Used by base.

=cut

sub get_resultset {
    my ( $self, $c ) = @_;

    return $c->model( $c->stash->{class} || $self->class );
}

=head2 get_object

=cut

sub get_object {
    my ( $self, $c, $pk ) = @_;
    return $c->stash->{resultset}->find($pk);
}


=head2 get_object_list

=cut

sub get_object_list : Private {
   my ( $self, $c ) = @_;

   my $rs = $c->stash->{resultset};
   return [ $rs->search( {} ) ];
}

=head2 delete_object

=cut

sub delete_object {
    my ( $self, $c ) = @_;

    return $c->stash->{object}->delete;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
