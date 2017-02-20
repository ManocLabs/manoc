# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
use strict;

package Manoc::Controller::Server;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

with 'Manoc::ControllerRole::CommonCRUD';

use Manoc::Form::Server;
use Manoc::Form::Server::Decommission;

=head1 NAME

Manoc::Controller::Server - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'server',
        }
    },
    class                   => 'ManocDB::Server',
    form_class              => 'Manoc::Form::Server',
    enable_permission_check => 1,
    view_object_perm        => undef,
    json_columns            => [ 'id', 'name' ],
);

=head2 create

=cut

before 'create' => sub {
    my ( $self, $c ) = @_;

    my $serverhw_id = $c->req->query_parameters->{'serverhw'};
    my $vm_id       = $c->req->query_parameters->{'vm'};
    my %form_defaults;

    if ( defined($serverhw_id) ) {
        $c->log->debug("new server using hardware $serverhw_id") if $c->debug;
        $form_defaults{serverhw} = $serverhw_id;
        $form_defaults{type}     = 'p';
    }
    if ( defined($vm_id) ) {
        $c->log->debug("new server using vm $vm_id") if $c->debug;
        $form_defaults{vm}   = $vm_id;
        $form_defaults{type} = 'v';
    }
    %form_defaults and
        $c->stash( form_defaults => \%form_defaults );
};

=head2 edit

=cut

before 'edit' => sub {
    my ( $self, $c ) = @_;

    my $object    = $c->stash->{object};
    my $object_pk = $c->stash->{object_pk};

    # decommissioned objects cannot be edited
    if ( $object->decommissioned ) {
        $c->res->redirect( $c->uri_for_action( 'server/view', [$object_pk] ) );
        $c->detach();
    }
};

=head2 decommission

=cut

sub decommission : Chained('object') : PathPart('decommission') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{object}, 'edit' );

    my $form = Manoc::Form::Server::Decommission->new( { ctx => $c } );

    $c->stash(
        form   => $form,
        action => $c->uri_for( $c->action, $c->req->captures ),
    );
    return unless $form->process(
        item   => $c->stash->{object},
        params => $c->req->parameters,
    );

    $c->response->redirect( $c->uri_for_action( 'server/view', [ $c->stash->{object_pk} ] ) );
    $c->detach();
}

=head2 restore

=cut

sub restore : Chained('object') : PathPart('restore') : Args(0) {
    my ( $self, $c ) = @_;

    my $server = $c->stash->{object};
    $c->require_permission( $server, 'edit' );

    if ( !$server->decommissioned ) {
        $c->response->redirect( $c->uri_for_action( 'server/view', [ $server->id ] ) );
        $c->detach();
    }

    if ( $c->req->method eq 'POST' ) {
        $server->restore;
        $server->update();
        $c->flash( message => "Server restored" );
        $c->response->redirect( $c->uri_for_action( 'server/view', [ $server->id ] ) );
        $c->detach();
    }

    # show confirm page
    $c->stash(
        title           => 'Restore server',
        confirm_message => 'Restore decommissioned server ' . $server->label . '?',
        template        => 'generic_confirm.tt',
    );
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
