# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
use strict;

package Manoc::Controller::Rack;
use Moose;
use namespace::autoclean;
use Data::Dumper;
BEGIN { extends 'Catalyst::Controller'; }
with 'Manoc::ControllerRole::JSONView';

use Manoc::Form::Rack;


=head1 NAME

Manoc::Controller::Rack - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path() : Args(0) {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for_action( 'rack/view' ) );
    $c->detach();
}

=head2 base

=cut

sub base : Chained('/') : PathPart('rack') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( resultset => $c->model('ManocDB::Rack') );
}

=head2 object

=cut

sub object : Chained('base') : PathPart('id') : CaptureArgs(1) {

    # $id = primary key
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

    $c->stash( template => 'rack/view.tt' );
}

=head2 list

=cut

sub fetch_list : Private {
    my ( $self, $c ) = @_;

    $c->stash(object_list => [ $c->stash->{resultset}->search(
        {},
        {
            prefetch => 'building',
            join     => 'building'
        }) ]
    );
}
 
sub list : Chained('base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('fetch_list');
    $c->stash( rack_table => $c->stash->{object_list} );
    $c->stash( template   => 'rack/list.tt' );
}


=head2 create

=cut

sub create : Chained('base') : PathPart('create') : Args() {
    my ( $self, $c, $id_build ) = @_;
    my $buildings = $c->model('ManocDB::Building');
    my $new_obj = $c->stash->{resultset}->new_result( {} );
    my ( $b, $form );
    $c->stash( default_backref => $c->uri_for('/rack/list') );

    #if the building is not specified in req->params
    if ( defined($id_build) ) {
        if ( !defined( $b = $buildings->find($id_build) ) ) {
            $c->stash( error_msg => "Trying to create a rack without a valid building" );
            $c->detach('/error/index');
        }
        $c->stash( building => $b->name, id => $id_build );
        $form = Manoc::Form::Rack->new(
            item                => $new_obj,
            default_building_id => $id_build
        );

    }

    $form or $form = Manoc::Form::Rack->new( item => $new_obj );
    $c->stash( form => $form, template => 'rack/create.tt' );

    if ( $c->req->param('form-rack.discard') ) {
        $c->detach('/follow_backref');
    }

    my $success = $form->process( params => $c->req->params );
    if(!$success) {
      $c->keep_flash('backref');
      return;
    }

    my $message = 'Success. Rack ' . $c->req->param('name') . ' created.';
    if ($c->stash->{is_xhr}) {
        $c->stash(message => $message);
        $c->stash(template => 'dialog/message.tt');
	$c->stash(no_wrapper => 1);
        $c->detach();
    }

    $c->flash( message => $message);
    $c->detach('/follow_backref');
}

=head2 delete

=cut

sub delete : Chained('object') : PathPart('delete') : Args(0) {
    my ( $self, $c ) = @_;

    my $rack = $c->stash->{'object'};
    my $id   = $rack->id;
    my $name = $rack->name;
    $c->stash( default_backref => $c->uri_for('/rack/list') );

    if ( lc $c->req->method eq 'post' ) {
        if ( $c->model('ManocDB::Device')->search( rack => $id )->count ) {
            $c->flash( error_msg => "Rack is not empty. Cannot be deleted." );
            $c->response->redirect( $c->uri_for_action( 'rack/view', [$id] ) );
            $c->detach();
        }

        my $building = $rack->building->id;
        $rack->delete;
        $c->flash( message => 'Success!! Rack ' . $name . '  deleted.' );

        $c->detach('/follow_backref');
    }
    else {
        $c->stash( template => 'generic_delete.tt' );
    }
}

=head2 edit

=cut

sub edit : Chained('object') : PathPart('edit') : Args(0) {
    my ( $self, $c ) = @_;

    my $item = $c->stash->{object};
    my $form = Manoc::Form::Rack->new( item => $item );

    $c->stash( form => $form, template => 'rack/edit.tt' );

    if ( $c->req->param('form-rack.discard') ) {
        $c->response->redirect(
            $c->uri_for_action( 'rack/view', [ $c->stash->{object}->id ] ) );
        $c->detach();
    }

    unless ( $form->process( params => $c->req->params ) ) {
        $c->keep_flash( ['backref'] );
        return;
    }

    $c->flash( message => 'Success! Rack ' . $c->req->param('name') . ' edited.' );
    if ( my $backref = $c->check_backref($c) ) {
        $c->response->redirect($backref);
        $c->detach();
    }

    $c->response->redirect( $c->uri_for_action( '/rack/view', [ $c->stash->{object}->id ] ) );
    $c->detach();
}



sub prepare_json_object : Private {
    my ($self, $rack) = @_;
    return {
	    id      => $rack->id,
	    name    => $rack->name,
	    building => $rack->building->id,
	    devices   => [ map +{ id => $_->id, name => $_->name }, $rack->devices ],
	   };
}


=head1 AUTHOR

gabriel&rigo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
