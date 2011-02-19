# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::User;
use Moose;
use Manoc::Form::User;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Manoc::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for('/user/list') );
    $c->detach();
}

=head2 base

=cut

sub base : Chained('/') : PathPart('user') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( resultset => $c->model('ManocDB::User') );
}

=head2 object

=cut

sub object : Chained('base') : PathPart('id') : CaptureArgs(1) {

    # $id = primary key
    my ( $self, $c, $id ) = @_;
    $c->stash( object => $c->stash->{resultset}->find($id) );

    if ( !defined( $c->stash->{object} ) ) {
        $c->stash( error_msg => "Object $id not found!" );
        $c->detach('/error/index');
    }
}

=head2 view

=cut

sub view : Chained('object') : PathPart('view') : Args(0) {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for('/user/list') );
    $c->detach();
}

=head2 create

=cut

sub create : Chained('base') : PathPart('create') : Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('save');
}

=head2 edit

=cut

sub edit : Chained('object') : PathPart('edit') : Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('save');
}

=head2 set_roles

=cut

sub set_roles : Chained('object') : PathPart('set_roles') : Args(0) {
    my ( $self, $c ) = @_;
    my $user = $c->stash->{object};

    my @all_roles = $c->model('ManocDB::Role')->search();
    $c->stash( default_backref => $c->uri_for_action('/user/list') );

    if ( lc $c->req->method eq 'post' ) {
        if ( $c->req->param('discard') ) {
            $c->detach('/follow_backref');
        }

        #Set user's roles
        my $user_roles_rs =
            $c->model('ManocDB::UserRole')->search( { 'user_id' => $user->id } );

        #Delete old roles
        $user_roles_rs->delete;

        #Retrieve all roles
        foreach (@all_roles) {

            #Add new roles
            my $role         = $_->role;
            my $user_role_id = $c->request->param($role);
            if ($user_role_id) {
                $c->model('ManocDB::UserRole')->create(
                    {
                        user_id => $user->id,
                        role_id => $c->request->param( $_->role ),
                    }
                );
            }
        }
        $c->flash( message => "Success. User's role edited." );
        $c->detach('/follow_backref');
    }

    my $user_roles_rs = $c->model('ManocDB::UserRole')->search( { user_id => $user->id } );
    my $user_roles = {};

    while ( my $e = $user_roles_rs->next ) {
        $user_roles->{ lc( $e->role->role ) } = 1;
    }

    $c->stash(
        template   => 'user/set_roles.tt',
        all_roles  => \@all_roles,
        user_roles => $user_roles
    );

}

=head2 save

=cut

sub save : Private {
    my ( $self, $c ) = @_;
    $c->stash( default_backref => $c->uri_for_action('/user/list') );

    my $item = $c->stash->{object} ||
        $c->stash->{resultset}->new_result( {} );
    $item->active(1);
    my $form = Manoc::Form::User->new( item => $item );

    $c->stash( form => $form, template => 'user/save.tt' );

    if ( $c->req->param('discard') ) {
        $c->detach('/follow_backref');
    }

    # the "process" call has all the saving logic,
    #   if it returns False, then a validation error happened
    return unless $form->process( params => $c->req->params );

    #If it'a a new user, set the default role (role \"user\")
    unless ( defined( $c->stash->{object} ) ) {
        my $role_user = $c->model('ManocDB::Role')->search( { role => "user" } )->single;
        unless ($role_user) {
            $c->stash( error_msg => "Role \"user\" not defined!" );
            $c->detach('/error/index');
        }
        $c->model('ManocDB::UserRole')->create(
            {
                user_id => $item->id,
                role_id => $role_user->id,
            }
        );
    }

    $c->flash( message => 'Success! User created.' );

    $c->detach('/follow_backref');
}

=head2 list

=cut

sub list : Chained('base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;

    my @user_table = $c->stash->{resultset}->all;

    $c->stash( user_table => \@user_table );
    $c->stash( template   => 'user/list.tt' );
}

=head2 delete

=cut

sub delete : Chained('object') : PathPart('delete') : Args(0) {
    my ( $self, $c ) = @_;
    my $user = $c->stash->{'object'};
    $c->stash( default_backref => $c->uri_for_action('/user/list') );

    if ( lc $c->req->method eq 'post' ) {

        $user->delete;
        $c->flash->{message} = 'Success!! User ' . $user->login . ' successful deleted.';

        $c->detach('/follow_backref');
    }
    else {
        $c->stash( template => 'generic_delete.tt' );
    }
}

=head2 switch_status

=cut

sub switch_status : Chained('object') : PathPart('switch_status') : Args(0) {
    my ( $self, $c ) = @_;
    my $user = $c->stash->{'object'};
    $user->active( !$user->active );
    $user->update;
    $c->response->redirect( $c->uri_for('/user/list') );
    $c->detach();
}

=head1 AUTHOR

Rigo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
