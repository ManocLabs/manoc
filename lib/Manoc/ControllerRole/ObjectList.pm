# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::ControllerRole::ObjectList;

use Moose::Role;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

requires 'base';

=head1 NAME

Manoc::ControllerRole::Object - Role for controllers accessing a resultrow

=head1 DESCRIPTION

This is a base role for Manoc controllers which manage a list of rows from
a resultset.

=head1 SYNOPSYS

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

  # manages /artist/
  sub list : Chained('object_list') : PathPart('') : Args(0) {
     my ( $self, $c ) = @_;
     
     # render with default template
     # objects are stored in $c->{object_list}
  }

=head1 ACTIONS

=head2 object_list

Load the list of objects from the resultset into the stash. Chained to base.
This is the point for chaining all actions using the list of object

=cut

sub object_list : Chained('base') : PathPart('') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( object_list => $self->get_object_list($c) );
}


=head1 METHODS

=head2 get_object_list

=cut

sub get_object_list : Private {
   my ( $self, $c ) = @_;

   my $rs = $c->stash->{resultset};
   return [ $rs->search( {} ) ];
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
