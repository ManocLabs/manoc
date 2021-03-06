package App::Manoc::Controller::APIv1::DHCPLease;
#ABSTRACT: Controller for DHCP APIs

use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends 'App::Manoc::ControllerBase::APIv1' }

=action base

Base action lease actions

=cut

sub base : Chained('deserialize') PathPart('dhcp/lease') CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( resultset => $c->model('ManocDB::DHCPLease') );
}

=action lease_post

POST api/v1/dhcp/lease

=cut

sub lease_post : Chained('base') PathPart('') POST {
    my ( $self, $c ) = @_;

    $c->stash(
        api_validate => {
            type  => 'hash',
            items => {
                server => {
                    type     => 'scalar',
                    required => 1,
                },
                leases => {
                    type     => 'array',
                    required => 1,
                },
            },
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

    my $records = $req_data->{leases};

    my $n_created = 0;
    my $rs        = $c->stash->{resultset};
    foreach my $r (@$records) {
        my $macaddr = $r->{macaddr}                                    or next;
        my $ipaddr  = App::Manoc::IPAddress::IPv4->new( $r->{ipaddr} ) or next;
        my $start   = $r->{start}                                      or next;
        my $end     = $r->{end}                                        or next;

        my $hostname = $r->{hostname};
        my $status   = $r->{status};

        $rs->update_or_create(
            {
                server   => $server,
                macaddr  => $macaddr,
                ipaddr   => $ipaddr,
                hostname => $hostname,
                start    => $start,
                end      => $end,
                status   => $status,
            }
        );
        $n_created++;
    }
    my $data = { message => "created $n_created entries", };

    $c->stash( api_response_data => $data );
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
