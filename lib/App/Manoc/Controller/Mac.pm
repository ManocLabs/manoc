package App::Manoc::Controller::Mac;
#ABSTRACT: Mac controller
use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 METHODS

=head2 view

=cut

sub view : Chained('/') : PathPart('mac') : Args(1) {
    my ( $self, $c, $macaddr ) = @_;

    $c->stash(
        macaddr => $macaddr,

        mat_results => [
            $c->model('ManocDB::Mat')->search(
                {
                    macaddr => $macaddr
                },
                {
                    prefetch => { 'device' => ['mng_url_format'] }
                }
            )->all
        ],

        arp_results => [
            $c->model('ManocDB::Arp')->search(
                {
                    macaddr => $macaddr,
                },
                {
                    order_by => { -desc => [ 'lastseen', 'firstseen' ] }
                }
            )->all
        ],

        dot11_results => [
            $c->model('ManocDB::Dot11Assoc')->search(
                {
                    macaddr => $macaddr
                },
                {
                    order_by => { -desc => [ 'lastseen', 'firstseen' ] }
                }
            )->all,
        ],

        serverhw => $c->model('ManocDB::ServerHW')
            ->search( { 'nics.macaddr' => $macaddr }, { join => 'nics' } ),

        reservations =>
            [ $c->model('ManocDB::DHCPReservation')->search( { macaddr => $macaddr } ) ],

        leases => [ $c->model('ManocDB::DHCPLease')->search( { macaddr => $macaddr } ) ],

    );

    #vendor info
    my $oui = $c->model('ManocDB::Oui')->find( substr( $macaddr, 0, 8 ) );
    $c->stash( vendor => $oui ? $oui->vendor : 'UNKNOWN' );
}

__PACKAGE__->meta->make_immutable;

1;
