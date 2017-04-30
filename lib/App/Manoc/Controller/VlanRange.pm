# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Controller::VlanRange;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }
with "App::Manoc::ControllerRole::CommonCRUD";
with "App::Manoc::ControllerRole::JSONView";

use App::Manoc::Form::VlanRange;
use App::Manoc::Form::VlanRange::Merge;
use App::Manoc::Form::VlanRange::Split;

BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'vlanrange',
        }
    },
    class                   => 'ManocDB::VlanRange',
    form_class              => 'App::Manoc::Form::VlanRange',
    enable_permission_check => 1,
    view_object_perm        => undef,
    json_columns            => [qw(id name description)],
);

=head1 NAME

App::Manoc::Controller::VlanRange - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 split

=cut

sub split : Chained('object') : PathPart('split') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{object}, 'edit' );

    my $form = App::Manoc::Form::VlanRange::Split->new( { ctx => $c } );

    $c->stash(
        form   => $form,
        action => $c->uri_for( $c->action, $c->req->captures ),
    );
    return unless $form->process(
        item   => $c->stash->{object},
        params => $c->req->parameters,
    );

    $c->response->redirect( $c->uri_for_action('vlanrange/list') );
    $c->detach();
}

sub merge : Chained('object') : PathPart('merge') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{object}, 'edit' );

    my $form = App::Manoc::Form::VlanRange::Merge->new( { ctx => $c } );

    $c->stash(
        form   => $form,
        action => $c->uri_for( $c->action, $c->req->captures ),
    );
    return unless $form->process(
        item   => $c->stash->{object},
        params => $c->req->parameters,
    );

    $c->response->redirect( $c->uri_for_action('vlanrange/list') );
    $c->detach();
}

=head1 METHODS

=cut

=head2 delete_object

=cut

sub delete_object {

    my ( $self, $c ) = @_;
    my $range = $c->stash->{'object'};
    my $id    = $range->id;
    my $name  = $range->name;

    if ( $range->vlans->count() ) {
        $c->flash( error_msg => "There are vlans in vlan range '$name'. Cannot delete it." );
        return undef;
    }

    return $range->delete;
}

=head2 get_form_success_url

=cut

sub get_form_success_url {
    my ( $self, $c ) = @_;

    return $c->uri_for_action( $c->namespace . "/list" );
}

=head2 get_object_list

=cut

sub get_object_list {
    my ( $self, $c ) = @_;
    return [
        $c->stash->{'resultset'}->search(
            {},
            {
                order_by => [ 'start', 'vlans.id' ],
                prefetch => 'vlans',
                join     => 'vlans',
            }
        )->all()
    ];
}

=head2 get_delete_failure_url

=cut

sub get_delete_failure_url {
    my ( $self, $c ) = @_;

    return $c->uri_for_action( $c->namespace . "/list" );
}

=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
