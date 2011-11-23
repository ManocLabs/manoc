# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Ip;
use Moose;
use namespace::autoclean;
use Manoc::Utils qw(print_timestamp clean_string int2ip ip2int check_addr);
use Manoc::Form::Ip_notes;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller'; }

use strict;

=head1 NAME

Manoc::Controller::Ip - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->stash( error_msg => "Missing Ip Address Parameter!" );
    $c->detach('/error/index');
}

=head2 base

=cut

sub base : Chained('/') PathPart('ip') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    if ( !defined($id) or !check_addr($id) ) {
        $c->stash( error_msg => "The ip is not a valid IPv4 address" );
        $c->detach('/error/index');
    }

    $c->stash( id => $id );
}

=head2 view

=cut

sub view : Chained('base') PathPart('view') Args(0) {
    my ( $self, $c ) = @_;

    my $n_res = $self->_get_ipinfo($c);
    $self->_get_hostinfo($c);
    $self->_get_dhcpinfo($c);

    $c->stash( template => 'ip/view.tt' );
}

=head2 get_ipinfo

=cut

sub _get_ipinfo : Private {
    my ( $self, $c ) = @_;
    my $id = $c->stash->{'id'};

    my @r = $c->model('ManocDB::Arp')->search(
        ipaddr => $id,
        { order_by => 'lastseen DESC, firstseen DESC' }
    );
    my @arp_results = map +{
        macaddr   => $_->macaddr,
        vlan      => $_->vlan,
        firstseen => print_timestamp( $_->firstseen ),
        lastseen  => print_timestamp( $_->lastseen )
    }, @r;
    $c->stash( arp_results => \@arp_results );

    my $note = $c->model('ManocDB::IpNotes')->find( { ipaddr => $id } );
    defined($note) ? $c->stash( 'notes' => $note->notes ) :
        $c->stash( 'notes' => '' ),

        @r = $c->model('ManocDB::IPRange')->search(
        [
            {
                'inet_aton(from_addr)' => { '<=' => ip2int($id) },
                'inet_aton(to_addr)'   => { '>=' => ip2int($id) },
            }
        ],
        { order_by => 'inet_aton(from_addr) DESC, inet_aton(to_addr)' }
        );
    my @subnet = map +{
        subnet_name => $_->name,
        from_addr   => $_->from_addr,
        to_addr     => $_->to_addr,
    }, @r;

    $c->stash( subnet => \@subnet, );
}

=head2 get_hostinfo

=cut

sub _get_hostinfo : Private {
    my ( $self, $c ) = @_;
    my $id = $c->stash->{'id'};

    my @r = $c->model('ManocDB::WinHostname')->search(
        ipaddr => $id,
        { order_by => 'name' }
    );
    my @hostnames = map +{
        name      => $_->name,
        firstseen => print_timestamp( $_->firstseen ),
        lastseen  => print_timestamp( $_->lastseen )
    }, @r;
    $c->stash( hostnames => \@hostnames );

    @r =
        $c->model('ManocDB::WinLogon')
        ->search( { ipaddr => $id }, { order_by => 'lastseen DESC, firstseen DESC' } );
    my @logons = map +{
        user      => $_->user,
        firstseen => print_timestamp( $_->firstseen ),
        lastseen  => print_timestamp( $_->lastseen )
    }, @r;
    $c->stash( logons => \@logons, );
}

=head _get_dhcpinfo

=cut

sub _get_dhcpinfo : Private {
    my ( $self, $c ) = @_;
    my @r;

    @r = $c->model('ManocDB::DHCPReservation')->search( { ipaddr => $c->stash->{id} } );
    my @reservations = map +{
        macaddr  => $_->macaddr,
        name     => $_->name,
        hostname => $_->hostname,
        server   => $_->server,
    }, @r;

    @r = $c->model('ManocDB::DHCPLease')->search( { ipaddr => $c->stash->{id} } );

    my @leases = map +{
        macaddr  => $_->macaddr,
        server   => $_->server,
        start    => print_timestamp( $_->start ),
        end      => print_timestamp( $_->end ),
        hostname => $_->hostname,
        status   => $_->status
    }, @r;
    $c->stash(
        leases       => \@leases,
        reservations => \@reservations,
    );
}

=head2 edit_notes

=cut

sub edit_notes : Chained('base') PathPart('edit_notes') Args(0) {
    my ( $self, $c ) = @_;
    my $id = $c->stash->{'id'};
    my $item = $c->model('ManocDB::IpNotes')->find( { ipaddr => $id } ) ||
        $c->model('ManocDB::IpNotes')->new_result( {} );
    $item->ipaddr($id);
    $c->stash( default_backref => $c->uri_for_action( 'ip/view', [$id] ) );

    my $form = Manoc::Form::Ip_notes->new( item => $item );

    $c->stash( form => $form, template => 'ip/edit_notes.tt' );

    if ( $c->req->param('discard') ) {
        $c->detach('/follow_backref');
    }

    return unless $form->process( params => $c->req->params, );
    $c->flash( message => 'Success! Note edit.' );

    $c->detach('/follow_backref');
}

=head2 delete_notes

=cut

sub delete_notes : Chained('base') PathPart('delete_notes') Args(0) {
    my ( $self, $c ) = @_;
    my $id = $c->stash->{'id'};
    my $item = $c->model('ManocDB::IpNotes')->find( { ipaddr => $id } );

    $c->stash( default_backref => $c->uri_for_action( 'ip/view', [$id] ) );

    if ( lc $c->req->method eq 'post' ) {
        $item and $item->delete;
        $c->flash( message => 'Success!! Note successful deleted.' );
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
