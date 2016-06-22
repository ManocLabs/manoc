# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
use strict;

package Manoc::Controller::Server;
use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }

use Manoc::Form::Server::Physical;

=head1 NAME

Manoc::Controller::ServerHW - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

has 'asset_form' => (
    is      => 'rw',
    lazy    => 1,
    default => sub { Manoc::Form::Server::Physical->new }
);

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path() : Args(0) {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for_action('server/list') );
    $c->detach();
}

=head2 base

=cut

sub base : Chained('/') : PathPart('serverhw') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( resultset => $c->model('ManocDB::ServerHW') );
}

=head2 object

=cut

sub object : Chained('base') : PathPart('id') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $c->stash( object => $c->stash->{resultset}->find($id) );

    if ( !$c->stash->{object} ) {
        $c->stash( error_msg => "Object $id not found!" );
        $c->detach('/error/index');
    }
}

=head2 view

=cut

sub view : Chained('object') : PathPart('view') : Args(0) {
    my ( $self, $c ) = @_;
    my $obj = $c->stash->{'object'};

    $c->stash( template => 'serverhw/view.tt' );
}

=head2 view

=cut


sub list : Chained('base') PathPart('list') Args(0) {
    my ( $self, $c ) = @_;

    my $assets = [ $c->stash->{resultset}->all ];
    $c->stash(
        objects  => $assets,
        template => 'server/list.tt'
    );
}

=head2 create

=cut

sub create : Chained('base') PathPart('create') Args(0) {
    my ( $self, $c ) = @_;

    # Create the empty asset
    my $attrs = {
        hwasset => {
            class => 'Server',
        }
    };
    $c->stash( object => $c->stash->{resultset}->new_result($attrs) );
    return $self->form($c);
}

=head2 edit

=cut

sub edit : Chained('object') PathPart('edit') Args(0) {
    my ( $self, $c ) = @_;
    return $self->form($c);
}

=head2 form

Used by add and edit

=cut

sub form {
    my ( $self, $c ) = @_;

    $c->stash(
        form     => $self->asset_form,
        template => 'serverhw/form.tt',
        action => $c->uri_for( $c->action, $c->req->captures )
    );

    return
        unless $self->asset_form->process(
        item   => $c->stash->{object},
        params => $c->req->parameters
        );
    $c->res->redirect( $c->uri_for( $self->action_for('list') ) );
}

sub delete : Chained('object') PathPart('delete') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( default_backref => $c->uri_for('/serverhw/list') );

    if ( lc $c->req->method eq 'post' ) {
        # TODO check foreign keys
        $c->stash->{object}->delete;
        $c->flash( message => 'Server deleted.' );
        $c->detach('/follow_backref');
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
