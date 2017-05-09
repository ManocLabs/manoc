package App::Manoc::ControllerRole::ResultSet;
#ABSTRACT:  Role for controllers accessing resultset

use Moose::Role;

##VERSION

use MooseX::MethodAttributes::Role;
use namespace::autoclean;

=head1 NAME

App::Manoc::ControllerRole::ResultSet -

=head1 DESCRIPTION

This is a base role for all Manoc controllers which manage a resultset.

=cut

has 'class' => ( is => 'ro', isa => 'Str', writer => '_set_class' );

=action setup

=cut

sub setup : Chained('/') : CaptureArgs(0) : PathPart('specify.in.subclass.config') { }

=action base

Add a resultset to the stash. Chained to setup.

=cut

sub base : Chained('setup') : PathPart('') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash( resultset => $self->get_resultset($c) );
}

=method get_resultset

It returns a resultset of the controller's class.  Used by base.

=cut

sub get_resultset {
    my ( $self, $c ) = @_;

    return $c->model( $c->stash->{class} || $self->class );
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
