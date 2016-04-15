# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Interface;
use Moose;
use namespace::autoclean;

use Manoc::Form::IfNotes;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Manoc::Controller::Interface - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base : Chained('/') : PathPart('interface') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( resultset => $c->model('ManocDB::IfStatus') );
}

=head2 object

=cut

sub object : Chained('base') : PathPart('') : CaptureArgs(2) {
    my ( $self, $c, $device_id, $iface ) = @_;

    my $object_pk = {
        device    => $device_id,
        interface => $iface,
    };

    $c->stash( object => $c->stash->{resultset}->find($object_pk) );
    if ( !$c->stash->{object} ) {
        $c->detach('/error/http_404');
    }

    $c->stash( object_pk => $object_pk );
}

=head2 view

=cut

sub view : Chained('object') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    my $object    = $c->stash->{'object'};
    my $object_pk = $c->stash->{object_pk};

    my $note = $c->model('ManocDB::IfNotes')->find($object_pk);
    $c->stash( notes => defined($note) ? $note->notes : '' );

    #MAT related results
    my @mat_rs = $c->model('ManocDB::Mat')
        ->search( $object_pk, { order_by => { -desc => [ 'lastseen', 'firstseen' ] } } );
    my @mat_results = map +{
        macaddr   => $_->macaddr,
        vlan      => $_->vlan,
        firstseen => $_->firstseen,
        lastseen  => $_->lastseen
    }, @mat_rs;

    $c->stash( mat_history => \@mat_results );
}

=head2 edit_notes

=cut

sub edit_notes : Chained('object') : PathPart('edit_notes') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{object}, 'edit' );

    my $object_pk = $c->stash->{object_pk};

    my $ifnotes = $c->model('ManocDB::IfNotes')->find($object_pk);
    $ifnotes or $ifnotes = $c->model('ManocDB::IfNotes')->new_result( {} );

    my $form = Manoc::Form::IfNotes->new( { %$object_pk, ctx => $c } );
    $c->stash( form => $form );
    return unless $form->process(
        params => $c->req->params,
        item   => $ifnotes
    );

    my $dest_url =
        $c->uri_for_action( 'interface/view', [ @$object_pk{ 'device', 'interface' } ] );
    $c->res->redirect($dest_url);
}

=head2 delete_notes

=cut

sub delete_notes : Chained('object') : PathPart('delete_notes') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{object}, 'delete' );

    my $object_pk = $c->stash->{object_pk};

    my $dest_url =
        $c->uri_for_action( 'interface/view', [ @$object_pk{ 'device', 'interface' } ] );

    my $item = $c->model('ManocDB::IfNotes')->find($object_pk);
    if ( !$item ) {
        $c->detach('/error/http_404');
    }

    if ( $c->req->method eq 'POST' ) {
        $item->delete;
        $c->res->redirect($dest_url);
        $c->detach();
    }
    else {
        $c->stash( template => 'generic_delete.tt' );
    }
}

=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
