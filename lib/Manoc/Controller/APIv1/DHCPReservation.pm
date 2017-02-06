# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::APIv1::DHCPReservation;
use Moose;
use namespace::autoclean;

=head1 NAME

Manoc::Controller::APIv1::DHCP - Catalyst Controller for DHCP APIs

=head1 DESCRIPTION

Catalyst Controller for implementing DHCP related web APIs.

=cut

BEGIN { extends 'Manoc::Controller::APIv1' }

=head1 METHODS

=cut

sub reservation_base : Chained('deserialize') PathPart('dhcp/reservation') CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( resultset => $c->model('ManocDB::DHCPReservation') );
}

=head2 reservation_post

POST api/v1/dhcp/reservation

=cut

sub reservation_post : Chained('reservation_base') PathPart('') POST {
    my ( $self, $c ) = @_;

    $c->stash(
        api_validate => {
            type  => 'hash',
            items => {
                server => {
                    type     => 'scalar',
                    required => 1,
                },
                reservations => {
                    type     => 'array',
                    required => 1,
                },
            }
        }
    );
    $c->forward('validate') or return;

    my $req_data = $c->stash->{api_request_data};

    my $server_name = $req_data->{server};
    my $server      = $c->model('ManocDB::DHCPServer')->find('name');
    if ( !$server ) {
        push @{ $c->stash->{api_field_errors} }, 'Unknown server';
        return;
    }
    my $rs        = $c->stash->{resultset};
    my $records   = $req_data->{reservations};
    my $n_created = 0;

    $c->schema->txn_do(
        sub {
            $server->reservations->update( on_server => 0 );

            foreach my $r (@$records) {
                my $macaddr = $r->{macaddr}                               or next;
                my $ipaddr  = Manoc::IPAddress::IPv4->new( $r->{ipaddr} ) or next;
                my $status  = $r->{server};
                my $hostname = $r->{hostname};
                my $name     = $r->{name};

                $rs->update_or_create(
                    {
                        macaddr   => $macaddr,
                        ipaddr    => $ipaddr,
                        hostname  => $hostname,
                        name      => $name,
                        server    => $server,
                        on_server => 1,
                    }
                );
                $n_created++;
            }
        }
    );
    my $data = { message => "created $n_created entries", };

    $c->stash( api_response_data => $data );
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
