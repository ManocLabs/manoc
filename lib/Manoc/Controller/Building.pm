# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Building;
use Moose;
use namespace::autoclean;
use Manoc::Form::Building;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Manoc::Controller::Building - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->response->redirect('building/list');
    $c->detach();
}

=head2 base

=cut

sub base : Chained('/') : PathPart('building') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( resultset => $c->model('ManocDB::Building') );
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

=head2 list

=cut

sub list : Chained('base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;

    my $build_schema = $c->stash->{resultset};

    my @building_table = map +{
        id      => $_->id,
        name    => $_->name,
        desc    => $_->description,
        n_racks => $_->racks->count()
        },
        $build_schema->all();

    $c->stash( building_table => \@building_table );
    $c->stash( template       => 'building/list.tt' );
}

=head2 view

=cut

sub view : Chained('object') : PathPart('view') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( template => 'building/view.tt' );
}

=head2 edit

=cut

sub edit : Chained('object') : PathPart('edit') : Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('save');
}

=head2 save

Handle create and edit resources

=cut

sub save : Private {
    my ( $self, $c ) = @_;
    my $item = $c->stash->{object} ||
        $c->stash->{resultset}->new_result( {} );

    #set the default backref according to the action (create or edit)
    my $def_br = $c->uri_for('/building/list');
    $def_br = $c->uri_for_action( 'building/view', [ $c->stash->{object}->id ] )
        if ( defined( $c->stash->{object} ) );
    $c->stash( default_backref => $def_br );

    my $form = Manoc::Form::Building->new( item => $item );
    $c->stash( form => $form, template => 'building/save.tt' );

    # the "process" call has all the saving logic,
    #   if it returns False, then a validation error happened

    if ( $c->req->param('discard') ) {
        $c->detach('/follow_backref');
    }
    return unless $form->process( params => $c->req->params );

    $c->flash( message => 'Success! Building created.' );
    $def_br = $c->uri_for_action( 'building/view', [ $item->id ] );
    $c->stash( default_backref => $def_br );
    $c->detach('/follow_backref');
}

=head2 create

=cut

sub create : Chained('base') : PathPart('create') : Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('save');
}

=head2 delete

=cut

sub delete : Chained('object') : PathPart('delete') : Args(0) {
    my ( $self, $c ) = @_;
    my $building = $c->stash->{'object'};
    my $id       = $building->id;
    my $name     = $building->name;
    $c->stash( default_backref => $c->uri_for_action('building/list') );

    if ( lc $c->req->method eq 'post' ) {
        if ( $c->model('ManocDB::Rack')->search( { building => $id } )->count ) {
            $c->flash( error_msg => 'Building is not empty. Cannot be deleted.' );
            $c->stash( default_backref => $c->uri_for_action( 'building/view', [$id] ) );
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

=head1 AUTHOR

Rigo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
