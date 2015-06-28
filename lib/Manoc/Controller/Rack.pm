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
    $c->stash( template   => 'rack/list.tt' );
}


=head2 create

=cut

sub create : Chained('base') : PathPart('create') : Args() {
    my ( $self, $c) = @_;

    my $building_id = $c->req->query_parameters->{'building'};
    $c->log->debug("new rack in $building_id");
    my $object = $c->stash->{resultset}->new_result({});
    my $form = Manoc::Form::Rack->new(
	item     => $object,
    );

    $c->stash( form => $form, template => 'rack/form.tt' );

    my $success = $form->process(
	params => $c->req->params,
	defaults => { building => $building_id, name => 'ciao' },
	use_defaults_over_obj => 1
    );
    if(!$success) {
	return;
    }

    my $message = 'Rack ' . $c->req->param('name') . ' created.';
    $c->flash( message => $message);
    if ($c->stash->{is_xhr}) {
        $c->stash(template => 'dialog/message.tt');
	$c->stash(no_wrapper => 1);
    }
}


=head2 edit

=cut

sub edit : Chained('object') : PathPart('edit') : Args(0) {
    my ( $self, $c ) = @_;

    my $item = $c->stash->{object};
    my $form = Manoc::Form::Rack->new( item => $item );

    $c->stash( form => $form, template => 'rack/form.tt' );
    unless ( $form->process( params => $c->req->params ) ) {
        return;
    }

    $c->flash( message => 'Rack modified ');
    $c->response->redirect( $c->uri_for_action( '/rack/view', [ $c->stash->{object}->id ] ) );
    $c->detach();
}


=head2 delete

=cut

sub delete : Chained('object') : PathPart('delete') : Args(0) {
    my ( $self, $c ) = @_;

    my $rack = $c->stash->{'object'};
    my $id   = $rack->id;
    my $name = $rack->name;


    if ( lc $c->req->method eq 'post' ) {
        if ( $c->model('ManocDB::Device')->search( rack => $id )->count ) {
            $c->flash( error_msg => "Rack is not empty. Cannot be deleted." );
            $c->response->redirect( $c->uri_for_action( 'rack/view', [$id] ) );
            $c->detach();
        }

        $rack->delete;
        $c->flash( message => 'Rack ' . $name . '  deleted.' );
	$c->response->redirect( $c->uri_for('/rack/list') );
        $c->detach();
    }
    else {
        $c->stash( template => 'generic_delete.tt' );
    }
}

 

sub prepare_json_object : Private {
    my ($self, $rack) = @_;
    return {
	    id      => $rack->id,
	    name    => $rack->name,
	    building => $rack->building->id,
	    building => {
		id   => $rack->building->id,
		name => $rack->building->name,
	    },
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
