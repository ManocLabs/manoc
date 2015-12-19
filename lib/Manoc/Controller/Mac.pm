# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Mac;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Manoc::Controller::Mac - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 view

=cut

sub view : Chained('/') : PathPart('mac') : Args(1) {
    my ( $self, $c, $macaddr ) = @_;

    $c->stash(
        macaddr => $macaddr,

        mat_results => [
            $c->model('ManocDB::MatArchive')->search(
                {
                    macaddr => $macaddr
                },
                {
                    prefetch => [ 'device', ],
                }
            ),
            $c->model('ManocDB::Mat')->search(
                {
                    macaddr => $macaddr
                },
                {
                    prefetch => { 'device_entry' => ['mng_url_format'] }
                }
            )
        ],

        arp_results => [
            $c->model('ManocDB::Arp')->search(
                {
                    macaddr => $macaddr,
                },
                {
                    order_by => { -desc => [ 'lastseen', 'firstseen' ] }
                }
            )
        ],

        dot11_results => [
            $c->model('ManocDB::Dot11Assoc')->search(
                {
                    macaddr => $macaddr
                },
                {
                    order_by => 'lastseen DESC, firstseen DESC'
                }
            )
        ],

        reservations =>
            [ $c->model('ManocDB::DHCPReservation')->search( { macaddr => $macaddr } ) ],

        leases => [ $c->model('ManocDB::DHCPLease')->search( { macaddr => $macaddr } ) ],

    );

    #vendor info
    my $oui = $c->model('ManocDB::Oui')->find( substr( $macaddr, 0, 8 ) );
    $c->stash( vendor => $oui ? $oui->vendor : 'UNKNOWN' );
}

=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
