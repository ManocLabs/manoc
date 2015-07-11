# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Interface;
use Moose;
use namespace::autoclean;
use Manoc::Utils qw(clean_string int2ip ip2int);
use Manoc::Form::IfNotes;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Manoc::Controller::Interface - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Manoc::Controller::Interface in Interface.');
}

sub base : Chained('/') : PathPart('interface') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( resultset => $c->model('ManocDB::IfStatus') );
}

=head2 object

=cut

sub object : Chained('base') : PathPart('id') : CaptureArgs(2) {
    my ( $self, $c, $id, $iface ) = @_;
    my $object = $c->stash(
        object => $c->stash->{resultset}->find(
            {
                device    => $id,
                interface => $iface,
            },
        ),
	device_id => $id,
	interface_name => $iface,
    );
    if ( !$c->stash->{object} ) {
        $c->stash( error_msg => "Object not found!" );
        $c->detach('/error/index');
    }
}

=head2 view

=cut

sub view : Chained('object') : PathPart('view') : Args(0) {
    my ( $self, $c ) = @_;
    my $object = $c->stash->{'object'};
    my $device = $object->device_info;
    $c->stash( device => $device );

    my $note = $c->model('ManocDB::IfNotes')->search(
        {
            device    => $device->id,
            interface => $object->interface,
        }
    )->first;

    $c->stash( notes => defined($note) ? $note->notes : '' );

    #MAT related results
    my @mat_rs = $c->model('ManocDB::Mat')->search(
        {
            device    => $device->id,
            interface => $object->interface,
        },
        { order_by => 'lastseen DESC, firstseen DESC', }
    );
    my @mat_results = map +{
        macaddr   => $_->macaddr,
        vlan      => $_->vlan,
        firstseen => print_timestamp( $_->firstseen ),
        lastseen  => print_timestamp( $_->lastseen )
    }, @mat_rs;

    $c->stash( mat_results => \@mat_results );
    $c->stash( template    => 'interface/view.tt' );
}

=head2 edit_notes

=cut

sub edit_notes : Chained('object') PathPart('edit_notes') Args(0) {
    my ( $self, $c ) = @_;
    my $iface        = $c->stash->{'object'};
    my $device_id    = $c->stash->{'device_id'};
  
    $c->stash( default_backref =>
      $c->uri_for_action( 'interface/view', [ $device_id, $iface->interface ] )
);

    my $item = $c->model('ManocDB::IfNotes')->find(
	{
	    device    => $device_id,
	    interface => $iface->interface,
	});
    $item or $item = $c->model('ManocDB::IfNotes')->new_result( {} );
    my $form = Manoc::Form::IfNotes->new(
	device    => $device_id,
	interface => $iface->interface,
    );
    $c->log->info("ITEM $device_id " .$item->interface);
    if ( $c->req->param('discard') ) {
        $c->detach('/follow_backref');
    }
    
    $c->stash(
	form => $form,
	template => 'interface/edit_notes.tt'
    );
    
    return unless $form->process(
	params => $c->req->params,
	item => $item );

    $c->flash( message => 'Success! Note edit.' );
    $c->detach('/follow_backref');
}

=head2 delete_notes

=cut

sub delete_notes : Chained('object') PathPart('delete_notes') Args(0) {
    my ( $self, $c ) = @_;
    my $iface = $c->stash->{'object'};

    $c->stash( default_backref =>
            $c->uri_for_action( 'interface/view', [ $iface->device, $iface->interface ] ) );
    my $item = $c->model('ManocDB::IfNotes')->search(
        {
            device    => $iface->device,
            interface => $iface->interface
        }
    );
    if ( lc $c->req->method eq 'post' ) {
        $item and $item->delete;
        $c->flash->{message} = 'Success!! Note successful deleted.';
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
