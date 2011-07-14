# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Mac;
use Moose;
use namespace::autoclean;
use Manoc::Utils qw(print_timestamp clean_string int2ip ip2int);

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Manoc::Controller::Mac - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->stash( error_msg => "Missing Mac Address Parameter!" );
    $c->detach('/error/index');
}

=head2 base

=cut

sub base : Chained('/') PathPart('mac') Args(1) {
    my ( $self, $c, $id ) = @_;

    if ( !defined($id) and $id eq '' ) {
        $c->stash( error_msg => "Object not found!" );
        $c->detach('/error/index');
    }

    $c->stash( id => $id );
    $c->stash(
        resultset => {
            mat         => $c->model('ManocDB::Mat'),
            mat_archive => $c->model('ManocDB::MatArchive'),
            arp         => $c->model('ManocDB::Arp'),
            dot11       => $c->model('ManocDB::Dot11Assoc'),
        }
    );

    #vendor info
    my $vendor = 'UNKNOWN';
    my $oui = $c->model('ManocDB::Oui')->find( substr( $id, 0, 8 ) );
    defined($oui) and $vendor = $oui->vendor;
    $c->stash( vendor => $vendor );

    #template
    $c->stash( template => 'macaddr.tt' );

    my $n_res = $self->_get_arp($c);
    $n_res += $self->_get_mat($c);
    $n_res += $self->_get_dot11($c);

    $self->_get_dhcpinfo($c);

    unless ($n_res) {
        $c->stash( message => 'Sorry, Mac Address not found!' );
    }

}

=head2 get_arp

=cut

sub _get_arp : Private {
    my ( $self, $c ) = @_;

    my @r = $c->stash->{'resultset'}->{'arp'}->search(
        {macaddr => $c->stash->{'id'}},
        { order_by => ['lastseen DESC, firstseen DESC'] }
    );
    my @arp_results = map +{
        ipaddr    => $_->ipaddr,
        vlan      => $_->vlan,
        firstseen => print_timestamp( $_->firstseen ),
        lastseen  => print_timestamp( $_->lastseen )
    }, @r;

    $c->stash( arp_results => \@arp_results );
    return scalar(@arp_results);
}

=head2 get_mat

=cut

sub _get_mat : Private {
    my ( $self, $c ) = @_;

    my @r = $c->stash->{'resultset'}->{'mat'}->search(
        {macaddr => $c->stash->{id}},
        {
            join => [ { 'device_entry' => 'mng_url_format' }, 'device_entry', ],
            prefetch => [ 'device_entry', { 'device_entry' => 'mng_url_format' }, ]
        }
    );
    my @mat_entries = map +{
        device      => $_->device_entry,
        iface       => $_->interface,
        vlan        => $_->vlan,
        firstseen_i => $_->firstseen,
        lastseen_i  => $_->lastseen,
        firstseen   => print_timestamp( $_->firstseen ),
        lastseen    => print_timestamp( $_->lastseen )
    }, @r;

    @r = $c->stash->{'resultset'}->{'mat_archive'}->search( 
							   { macaddr  => $c->stash->{'id'} }, 
							   { prefetch => [ 'device', ]}, 
							  );
    my @mat_archive_entries = map +{
        arch_device_ip   => $_->device->ipaddr,
        arch_device_name => $_->device->name,
        vlan             => $_->vlan,
        firstseen_i      => $_->firstseen,
        lastseen_i       => $_->lastseen,
        firstseen        => print_timestamp( $_->firstseen ),
        lastseen         => print_timestamp( $_->lastseen )
    }, @r;

    my @mat_results = sort {
        $b->{lastseen_i} <=> $a->{lastseen_i} ||
            $b->{firstseen_i} <=> $a->{firstseen_i}
    } ( @mat_entries, @mat_archive_entries );

    $c->stash( mat_results => \@mat_results );
    return scalar(@mat_results);

}

=head _get_dot11

=cut

sub _get_dot11 : Private {
    my ( $self, $c ) = @_;

    my @r = $c->stash->{'resultset'}->{'dot11'}->search(
        {macaddr => $c->stash->{id}},
        { order_by => ['lastseen DESC, firstseen DESC'] }
    );
    my @dot11_results = map +{
        device    => $_->device,
        ssid      => $_->ssid,
        ipaddr    => $_->ipaddr,
        vlan      => $_->vlan,
        firstseen => print_timestamp( $_->firstseen ),
        lastseen  => print_timestamp( $_->lastseen )
    }, @r;

    $c->stash( dot11_results => \@dot11_results );
    return scalar(@dot11_results);
}

=head _get_dhcpinfo

=cut

sub _get_dhcpinfo : Private {
    my ( $self, $c ) = @_;
    my @r;

    @r = $c->model('ManocDB::DHCPReservation')->search( { macaddr => $c->stash->{id} } );
    my @reservations = map +{
        ipaddr   => $_->ipaddr,
        name     => $_->name,
        hostname => $_->hostname,
        server   => $_->server,
    }, @r;

    @r = $c->model('ManocDB::DHCPLease')->search( { macaddr => $c->stash->{id} } );

    my @leases = map +{
        ipaddr   => $_->ipaddr,
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

=head1 AUTHOR

Rigo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
