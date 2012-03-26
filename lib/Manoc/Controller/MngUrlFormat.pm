# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::MngUrlFormat;
use Moose;
use namespace::autoclean;

use Manoc::Form::MngUrlFormat;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Manoc::Controller::MngUrl - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->response->redirect('/mngurlformat/list');
    $c->detach();
}

=head2 base

=cut

sub base : Chained('/') : PathPart('mngurlformat') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( resultset => $c->model('ManocDB::MngUrlFormat') );
}

=head2 object

=cut

sub object : Chained('base') : PathPart('id') : CaptureArgs(1) {

    # $id = primary key
    my ( $self, $c, $id ) = @_;

    return if ( $id eq '' );
    $c->stash( object => $c->stash->{resultset}->find($id) );

    if ( !defined( $c->stash->{object} ) ) {
        $c->stash( error_msg => "Object $id not found!" );
        $c->detach('/error/index');
    }
}

=head2 list

=cut

sub list : Chained('base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;

    my $rs = $c->stash->{resultset};

    $c->stash( obj_list => [ $rs->all() ] );
    $c->stash( template => 'mngurlformat/list.tt' );
}

=head2 edit

=cut

sub edit : Chained('object') : PathPart('edit') : Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('save');

}

=head2 set_default

=cut

sub set_default : Chained('object') : PathPart('set_default') : Args(0) {
    my ( $self, $c ) = @_;
    my ($it, $e);

    if ( lc $c->req->method eq 'post' ) {
      my $it = $c->model('ManocDB::Device')->search();
      while($e = $it->next){
	$e->mng_url_format($c->stash->{object}->id);
	$e->update;
      }
      $c->stash(message => "Default Management URL setted to ".$c->stash->{object}->name);
      $c->forward('list');
    }
    else {
      $c->stash( template => 'generic_confirm.tt' );
    }

}



=head2 create

=cut

sub create : Chained('base') : PathPart('create') : Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('save');
}

sub save : Private {
    my ( $self, $c ) = @_;

    my $item = $c->stash->{object} ||
        $c->stash->{resultset}->new_result( {} );

    my $form = Manoc::Form::MngUrlFormat->new( item => $item );
    $c->stash( form => $form, template => 'mngurlformat/save.tt' );
    $c->stash( default_backref => $c->uri_for_action('mngurlformat/list') );

    # the "process" call has all the saving logic,
    #   if it returns False, then a validation error happened

    my $is_create = !defined( $c->stash->{'object'} );
    if ( $c->req->param('discard') ) {
        $c->detach('/follow_backref');
    }

    return unless $form->process( params => $c->req->params );

    $c->flash( message => 'Saved.' );

    $c->detach('/follow_backref');

    # prepare template
    $c->stash( template => 'mngurlformat/save.tt' );
}

=head2 delete

=cut

sub delete : Chained('object') : PathPart('delete') : Args(0) {
    my ( $self, $c ) = @_;

    my $building = $c->stash->{'object'};
    my $id       = $building->id;
    my $name     = $building->name;
    $c->stash( default_backref => $c->uri_for_action('mngurlformat/list') );

    if ( lc $c->req->method eq 'post' ) {
        if ( $c->model('ManocDB::Device')->search( { mng_url_format => $id } )->count ) {
            $c->flash( error_msg => 'Format in use. Cannot be deleted.' );
            $c->detach('/follow_backref');
        }

        $building->delete;

        $c->flash( message => 'Success!!  ' . $name . ' successful deleted.' );
        $c->detach('/follow_backref');
    }
    else {
        $c->stash( template => 'generic_delete.tt' );
    }

}

1;
