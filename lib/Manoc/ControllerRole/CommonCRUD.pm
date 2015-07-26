# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::ControllerRole::CommonCRUD;

use Moose::Role;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

with 'Manoc::ControllerRole::ResultSet';
with 'Manoc::ControllerRole::ObjectForm';


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
Load the list of objects from the resultset into the stash. Chained to base.
This is the point for chaining all actions using the list of object

=cut

sub object_list : Chained('base') : PathPart('') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( object_list => $self->get_object_list($c) );
}


=head2 list

Display a list of items.

=cut

sub list : Chained('object_list') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $c->stash(
        title    => $self->list_page_title,
        template => $self->list_page_template
    );
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
            $c->res->redirect( $c->uri_for_action($c->namespace . "/list") );
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


=head1 METHODS

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
