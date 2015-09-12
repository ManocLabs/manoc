# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Ip;
use Moose;
use namespace::autoclean;
use Manoc::IPAddress::IPv4;
use Manoc::Utils::IPAddress qw(check_addr);
use Manoc::Form::Ip;

BEGIN { extends 'Catalyst::Controller'; }

use strict;

=head1 NAME

Manoc::Controller::Ip - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 base

=cut

sub base : Chained('/') PathPart('ip') CaptureArgs(1) {
    my ( $self, $c, $address ) = @_;

    if ( !check_addr($address) ) {
	$c->detach('/error/http_404');
    }

    $c->stash(
	ipaddress => Manoc::IPAddress::IPv4->new( $address ),
	object    => $c->model('ManocDB::Ip')->find( { ipaddr => $address } )
    );
}

=head2 view

=cut

sub view : Chained('base') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    my $ipaddress = $c->stash->{ipaddress};

    $c->stash(
	device => $c->model('ManocDB::Device')->search({mng_address => $ipaddress})->first
    );

    $c->stash(
	ipblocks => [ $c->model('ManocDB::IPBlock')->including_address_ordered($ipaddress) ]
    );

    $c->stash(
	networks => [ $c->model('ManocDB::IPNetwork')->including_address_ordered($ipaddress) ]
    );

    $c->stash(
	arp_entries => [ $c->model('ManocDB::Arp')->search_by_ipaddress_ordered($ipaddress) ]
    );
    
    $c->stash(
	hostnames => [ $c->model('ManocDB::WinHostname')->search(
	    { ipaddr   => $ipaddress->padded },
	    { order_by => 'lastseen DESC, firstseen DESC' }
	) ],
    );

    $c->stash(
	logons => [ $c->model('ManocDB::WinLogon')->search(
	    { ipaddr   => $ipaddress->padded },
	    { order_by => 'lastseen DESC' },
	) ],
    );

    $c->stash(
	reservations => [ $c->model('ManocDB::DHCPReservation')->search(
	    { ipaddr => $ipaddress->padded }
	) ],
    );

    $c->stash(
	leases => [ $c->model('ManocDB::DHCPLease')->search(
	    { ipaddr => $ipaddress->padded }
	) ],
    );
}

=head2 edit

=cut

sub edit : Chained('base') PathPart('edit') Args(0) {
    my ( $self, $c ) = @_;

    my $item      = $c->stash->{object};
    my $ipaddress = $c->stash->{ipaddress};
    if (!$item) {
	$item = $c->model('ManocDB::Ip')->new_result( {} );
	$item->ipaddr($ipaddress);
    }

    my $form = Manoc::Form::Ip->new(ipaddr => $ipaddress->address);
    $c->stash( form => $form);

    return unless $form->process(
	params => $c->req->params,
	item   => $item
    );

    $c->res->redirect($c->uri_for_action( 'ip/view', [$ipaddress->address] ) );
    $c->detach();
}

=head2 delete

=cut

sub delete : Chained('base') : PathPart('delete') : Args(0) {
    my ( $self, $c ) = @_;

    my $item      = $c->stash->{object};
    my $ipaddress = $c->stash->{ipaddress};

    my $redirect_url = $c->uri_for_action( 'ip/view', [$ipaddress->address] );
    unless ($item) {
	$c->res->redirect($redirect_url);
	$c->detach;
    }

    if ( $c->req->method eq 'POST' ) {
        $item->delete;
	$c->res->redirect($redirect_url);
	$c->detach;
    }
    else {
        $c->stash( template => 'generic_delete.tt' );
    }
}


=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
