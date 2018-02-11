package App::Manoc::Controller::Arp;
#ABSTRACT: Arp Catalyst Controller

use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }
with
    'App::Manoc::ControllerRole::ResultSet',
    'App::Manoc::ControllerRole::JQDatatable';

use App::Manoc::Utils::Datetime qw(print_timestamp str2seconds);

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'arp',
        }
    },
    class => 'ManocDB::Arp',

    datatable_row_callback => sub {
        my ( $self, $c, $row ) = @_;
        my $address = App::Manoc::IPAddress::IPv4->new( $row->get_column('ipaddr') );
        return [
            "$address",
            print_timestamp( $row->get_column('firstseen') ),
            print_timestamp( $row->get_column('lastseen') ),
        ];
    },
    datatable_search_columns => [qw/ipaddr/],
    datatable_columns        => [qw/ipaddr firstseen lastseen/]
);

=head1 DESCRIPTION

Catalyst Controller.

=cut

=action list

=cut

sub list : Chained('base') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    if ( my $days = $c->req->params->{days} ) {
        $c->stash( days => int($days) );
    }

    my $network_id = $c->req->params->{ipnetwork};
    if ( defined($network_id) ) {
        my $network = $c->model('ManocDB::IPNetwork')->find($network_id);

        # used in template
        $network and $c->stash( ipnetwork => $network );
    }

    my $block_id = $c->req->params->{ipblock};
    if ( defined($block_id) ) {
        my $ipblock = $c->model('ManocDB::IPBlock')->find($block_id);

        # used in template
        $ipblock and $c->stash( ipblock => $ipblock );
    }
}

=method get_datatable_resultset

=cut

sub get_datatable_resultset {
    my ( $self, $c ) = @_;

    my $rs = $c->stash->{resultset};

    my $network_id = $c->req->params->{ipnetwork};
    if ( defined($network_id) ) {
        my $network = $c->model('ManocDB::IPNetwork')->find($network_id);

        $c->debug and $c->log->debug("Using network $network_id for filtering ARP");
        $network and $rs = $network->arp_entries;
    }

    my $block_id = $c->req->params->{ipblock};
    if ( defined($block_id) ) {
        my $block = $c->model('ManocDB::IPBlock')->find($block_id);

        $c->debug and $c->log->debug("Using block $block_id for filtering ARP");
        $block and $rs = $block->arp_entries;
    }

    my $days = $c->req->params->{days};
    if ( $days && int($days) ) {
        $rs = $rs->search( { lastseen => { '>=' => time - str2seconds( int($days), 'd' ) } } );
    }

    return $rs;
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
