package App::Manoc::ControllerRole::Object;
#ABSTRACT: Role for controllers accessing a result row

use Moose::Role;

##VERSION

use namespace::autoclean;

use MooseX::MethodAttributes::Role;

requires 'base';

has find_object_options => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} }
);

=head1 DESCRIPTION

This is a base role for all Manoc controllers which manage a row from
a resultset.

=head1 SYNPOSYS

  package App::Manoc::Controller::Artist;

  use Moose;
  extends "Catalyst::Controller";
  with "App::Manoc::ControllerRole::Object";

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
=cut

=action object

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

=method get_object

Search the object in stash->{resultset} using given the pk.

=cut

sub get_object {
    my ( $self, $c, $pk ) = @_;
    my $options = $c->stash->{find_object_options} || $self->find_object_options;
    return $c->stash->{resultset}->find( $pk, $options );
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End: