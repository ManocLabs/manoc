package App::Manoc::Controller::Query;
#ABSTRACT: Controller for query and reports

use Moose;

##VERSION

use namespace::autoclean;
use App::Manoc::Utils qw(clean_string);
use App::Manoc::Utils::Datetime qw(str2seconds);
use App::Manoc::Utils::IPAddress qw(unpadded_ipaddr);

BEGIN { extends 'Catalyst::Controller'; }

=action index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
}

=action base

=cut

sub base : Chained('/') : PathPart('query') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

=action statistics

=cut

sub statistics : Chained('base') : PathPart('statistics') : Args(0) {
    my ( $self, $c ) = @_;
    my $schema = $c->model('ManocDB');

    my ( $r, $rs );
    my %vlan_stats;

    $rs = $schema->resultset('Mat')->search(
        {},
        {
            select   => [ 'vlan', { count => { distinct => 'macaddr' } } ],
            as       => [ 'vlan', 'count' ],
            group_by => ['vlan'],
        }
    );
    while ( $r = $rs->next ) {
        $vlan_stats{ $r->get_column('vlan') }->{macaddr} = $r->get_column('count');
    }

    $rs = $schema->resultset('Arp')->search(
        {},
        {
            select   => [ 'vlan', { count => { distinct => 'ipaddr' } } ],
            as       => [ 'vlan', 'count' ],
            group_by => ['vlan'],
        }
    );

    while ( $r = $rs->next ) {
        $vlan_stats{ $r->get_column('vlan') }->{ipaddr} = $r->get_column('count');
    }

    # TODO move to vlan controller
    my @vlan_table;
    foreach my $vlan ( sort { $a <=> $b } keys %vlan_stats ) {
        push @vlan_table,
            {
            vlan    => $vlan,
            macaddr => $vlan_stats{$vlan}->{macaddr} || 'na',
            ipaddr  => $vlan_stats{$vlan}->{ipaddr}  || 'na',
            };
    }

    $c->stash(
        disable_pagination => 1,
        vlan_table         => \@vlan_table,
        #        db_stats           => \@db_stats,
        template => 'query/stats.tt',
    );
}

=action ipconflict

=cut

sub ipconflict : Chained('base') : PathPart('ipconflict') : Args(0) {
    my ( $self, $c ) = @_;
    my $schema = $c->model('ManocDB');
    my ( $r, $rs );

    my @conflicts =
        map {
        ipaddr    => unpadded_ipaddr( $_->get_column('ipaddr') ),
            count => $_->get_column('count'),
        }, $schema->resultset('Arp')->search_conflicts;

    my @multihomed =
        map { macaddr => $_->get_column('macaddr'), count => $_->get_column('count'), },
        $schema->resultset('Arp')->search_multihomed;

    $c->stash(
        multihomed => \@multihomed,
        conflicts  => \@conflicts,
        template   => 'query/ipconflict.tt',
    );
}

=action multihost

=cut

sub multihost : Chained('base') : PathPart('multihost') : Args(0) {
    my ( $self, $c ) = @_;
    my $schema = $c->model('ManocDB::Mat');
    my ( $rs, $r );

    my @multihost_ifaces;

    #    $rs = $schema->resultset('Mat')->search_multihost;

    $rs = $schema->search(
        { 'archived' => 0 },
        {
            select => [
                'me.device',                            'me.interface',
                { count => { distinct => 'macaddr' } }, 'ifstatus.description',
            ],

            as       => [ 'device',    'interface', 'count', 'description', ],
            group_by => [ 'me.device', 'me.interface' ],
            having   => { 'COUNT(DISTINCT(macaddr))' => { '>', 1 } },
            order_by => [ 'me.device', 'me.interface' ],
            alias    => 'me',
            from     => [
                { me => 'mat' },
                [
                    { 'ifstatus' => 'if_status' },
                    {
                        'ifstatus.device'    => 'me.device',
                        'ifstatus.interface' => 'me.interface',
                    }
                ]
            ]
        }
    );

    while ( $r = $rs->next() ) {
        my $id          = $r->get_column('device');
        my $iface       = $r->get_column('interface');
        my $count       = $r->get_column('count');
        my $description = $r->get_column('description') || "";
        my $device      = $c->model('ManocDB::Device')->find($id);

        #TODO: if the device was deleted?
        push @multihost_ifaces,
            {
            id          => $id,
            interface   => $iface,
            description => $description,
            count       => $count,
            };
    }
    $c->stash( multihost_ifaces => \@multihost_ifaces );
    $c->stash( template         => 'query/multihost.tt' );
}

=action unused_ifaces

=cut

sub unused_ifaces : Chained('base') : PathPart('unused_ifaces') : Args(0) {
    my ( $self, $c ) = @_;

    my $device_id = clean_string( $c->req->param('device') );
    my $days      = clean_string( $c->req->param('days') );

    $days =~ /^\d+$/ or $days = 0;

    my $schema = $c->model('ManocDB');

    my @device_list =
        sort { $a->{label} cmp $b->{label} }
        map +{
        id       => $_->id,
        label    => lc( $_->name ) . ' (' . $_->id->address . ')',
        selected => $device_id eq $_->id,
        },
        $schema->resultset('Device')->all();

    #    unshift @device_list, { id => "(All)", } TODO

    my @unused_ifaces;

    if ($device_id) {
        my ( $rs, $r );
        $rs = $schema->resultset('IfStatus')->search_unused($device_id);

        while ( $r = $rs->next() ) {
            push @unused_ifaces,
                {
                id          => $r->device,
                interface   => $r->interface,
                description => $r->description,
                };
        }
    }

    $c->stash(
        device_list   => \@device_list,
        unused_ifaces => \@unused_ifaces,
        template      => 'query/unused_ifaces.tt',
    );
}

=action unknown_devices

=cut

sub unknown_devices : Chained('base') : PathPart('unknown_devices') : Args(0) {
    my ( $self, $c ) = @_;

    my $schema = $c->model('ManocDB');

    my $search_attribs = {
        alias => 'me',
        from  => [
            { me => 'cdp_neigh', },
            [
                {
                    to_dev     => 'devices',
                    -join_type => 'LEFT'
                },
                { 'to_dev.id' => 'me.to_device', }
            ],
        ],
        join     => { 'from_device' => 'mng_url_format' },
        prefetch => { 'from_device' => 'mng_url_format' }

    };

    my @results =
        $schema->resultset('CDPNeigh')->search( { 'to_dev.id' => undef }, $search_attribs );
    my @unknown_devices = map +{
        device      => $_->from_device,
        from_device => $_->from_device,
        from_iface  => $_->from_interface,
        to_device   => $_->to_device->address,
        to_iface    => $_->to_interface,
        date        => $_->last_seen
    }, @results;

    $c->stash(
        unknown_devices => \@unknown_devices,
        template        => 'query/unknown_devices.tt'
    );
}

=action portsecurity

=cut

sub portsecurity : Chained('base') : PathPart('portsecurity') : Args(0) {
    my ( $self, $c ) = @_;
    my $schema = $c->model('ManocDB');

    my @rs = $schema->resultset('IfStatus')->search(
        { cps_status => 'shutdown' },
        {
            order_by => 'device_id, interface',
            join     => 'device'
        }
    );

    my @table = map {
        id              => $_->device,
            device_name => $_->device->name,
            interface   => $_->interface,
            description => $_->description,
            cps_count   => $_->cps_count,
    }, @rs;

    $c->stash( table => \@table, template => 'query/portsecurity.tt' );

}

=action multi_mac

=cut

sub multi_mac : Chained('base') : PathPart('multi_mac') : Args(0) {
    my ( $self, $c ) = @_;
    my $schema = $c->model('ManocDB');
    my $results;
    my $e;
    my @multimacs;

    $results = $schema->resultset('Mat')->search(
        { archived => '0' },
        {
            select   => [ 'macaddr', { count => 'device' } ],
            as       => [ 'macaddr', 'devs' ],
            group_by => ['macaddr'],
            having   => { 'COUNT(device)' => { '>', 1 } },
        }
    );

    while ( $e = $results->next() ) {
        my $macaddr = $e->get_column('macaddr');
        my $devs    = $e->get_column('devs');
        my $last    = $e->get_column('lastseen');

        push @multimacs,
            {
            macaddr => $macaddr,
            devs    => $devs,
            };
    }

    $c->stash( multimacs => \@multimacs, template => 'query/multi_mac.tt' );
}

=action new_devices

=cut

sub new_devices : Chained('base') : PathPart('new_devices') : Args(0) {
    my ( $self, $c ) = @_;
    my $schema = $c->model('ManocDB');
    my @results;
    my $e;
    my @multimacs;
    my $days = clean_string( $c->req->param('days') ) || "";
    $days =~ /^\d+$/ or $days = "";

    if ($days) {
        my $query_time = time - str2seconds( $days . "d" );

        @results = $schema->resultset('Mat')->search(
            {},
            {
                select =>
                    [ 'macaddr', 'device', 'interface', 'firstseen', { min => 'firstseen' } ],
                as       => [ 'macaddr', 'device', 'interface', 'firstseen', 'fs' ],
                group_by => ['macaddr'],
                having   => { 'MIN(firstseen)' => { '>', $query_time } },
            }
        );

        my @new_devices = map +{
            macaddr => $_->macaddr,
            device  => $_->device_entry,
            iface   => $_->interface,
            from    => $_->firstseen,
        }, @results;

        $c->stash( new_devs => \@new_devices );
    }

    $c->stash(
        days     => $days,
        template => 'query/new_devices.tt'
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
