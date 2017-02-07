# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::ControllerRole::Object;

use Moose::Role;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

requires 'base';

=head1 NAME

Manoc::ControllerRole::Object - Role for controllers accessing a resultrow

=head1 DESCRIPTION

This is a base role for all Manoc controllers which manage a row from
a resultset.


=head1 SYNPOSYS

  package Manoc::Controller::Artist;

  use Moose;
  extends "Catalyst::Controller";
  with "Manoc::ControllerRole::Object";

  __PACKAGE__->config(
      # define PathPart
      action => {
          setup => {
              PathPart => 'artist',
          }
      },
      class      => 'ManocDB::Artist',
      );

  # manages /artist/<id>
  sub view : Chained('object') : PathPart('') : Args(0) {
     my ( $self, $c ) = @_;

     # render with default template
     # object will be accessible in $c->{object}
     # object id in object_pk
  }

=head1 ACTIONS

=head2 object

This action is the chain root for all the actions which operate on a
single identifer, e.g. view, edit, delete.

=cut

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash(
        object    => $self->get_object( $c, $id ),
        object_pk => $id
    );
    if ( !$c->stash->{object} ) {
        $c->detach('/error/http_404');
    }
}

=head1 METHODS

=head2 get_object

Search the object in stash->{resultset} using given the pk.

=cut

sub get_object {
    my ( $self, $c, $pk ) = @_;
    return $c->stash->{resultset}->find($pk);
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
