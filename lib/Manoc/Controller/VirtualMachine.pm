# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
use strict;

package Manoc::Controller::VirtualMachine;
use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }
with 'Manoc::ControllerRole::CommonCRUD';
with 'Manoc::ControllerRole::JSONView';

use Manoc::Form::VirtualMachine;

=head1 NAME

Manoc::Controller::VirtualMachine - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'virtualmachine',
        }
    },
    class      => 'ManocDB::VirtualMachine',
    form_class => 'Manoc::Form::VirtualMachine',

    create_page_title       => 'Create virtual machine',
    edit_page_title         => 'Edit virtual machine',

    json_columns => [ 'id', 'name' ],
);


=head2 edit

=cut


before 'edit' => sub {
    my ( $self, $c ) = @_;

    my $object    = $c->stash->{object};
    my $object_pk = $c->stash->{object_pk};

    # decommissioned objects cannot be edited
    if ( $object->decommissioned ) {
        $c->flash( message => "Cannot edit a decommissioned virtual machine" );
        $c->res->redirect( $c->uri_for_action('virtualmachine/view', [ $object_pk ] ) );
        $c->detach();
    }
};

=head2 decommission

=cut

sub decommission : Chained('object') : PathPart('decommission') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};
    $c->require_permission( 'virtualmachine', 'edit' );

    if ($object->in_use) {
        $c->response->redirect(
            $c->uri_for_action( 'virtualmachine/view', [ $c->stash->{object_pk} ] ) );
        $c->detach();
    }

    if ( $c->req->method eq 'POST' ) {
        $object->decommission;
        $object->update();
        $c->flash( message => "Virtual machine decommissioned" );
        $c->response->redirect(
            $c->uri_for_action( 'virtualmachine/view', [ $c->stash->{object_pk} ] ) );
        $c->detach();
    }

    # show confirm page
    $c->stash(
        title           => 'Decommission virtual machine',
        confirm_message => 'Decommission virtual machine ' . $object->label . '?',
        template        => 'generic_confirm.tt',
    );
}

=head2 restore

=cut

sub restore : Chained('object') : PathPart('restore') : Args(0) {
    my ( $self, $c ) = @_;

    my $vm = $c->stash->{object};
    $c->require_permission( $vm, 'edit' );

    if (! $vm->decommissioned ) {
        $c->response->redirect(
            $c->uri_for_action( 'virtualmachine/view', [ $vm->id ] ) );
        $c->detach();
    }

    if ( $c->req->method eq 'POST' ) {
        $vm->restore;
        $vm->update();
        $c->flash( message => "Virtual machine restored" );
        $c->response->redirect(
            $c->uri_for_action( 'virtualmachine/view', [ $vm->id ] ) );
        $c->detach();
    }

    # show confirm page
    $c->stash(
        title           => 'Restore  virtual machine',
        confirm_message => 'Restore decommissioned virtual machine ' . $vm->name . '?',
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
