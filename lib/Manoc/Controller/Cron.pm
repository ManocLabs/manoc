# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Cron;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Manoc::Controller::Cron - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    use Data::Dumper;
    $c->log->debug( Dumper( $c->scheduler_state ) );
    $c->response->redirect($c->uri_for_action('/search/index'));
}

sub remove_sessions : Path('/cron/remove_sessions ') : Args(0) {
    my ( $self, $c ) = @_;

    $c->delete_expired_sessions;
}

=head1 AUTHOR

Rigo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
