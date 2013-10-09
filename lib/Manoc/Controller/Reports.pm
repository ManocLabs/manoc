# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Reports;
use Moose;
use namespace::autoclean;
use Manoc::Utils;

BEGIN { extends 'Catalyst::Controller'; }

use Manoc::Utils qw(print_timestamp str2seconds);

=head1 NAME

Manoc::Controller::Reports - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
}

=head2 base

=cut

sub base : Chained('/') : PathPart('reports') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

=head2 stats

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

    my @vlan_table;
    foreach my $vlan ( sort { $a <=> $b } keys %vlan_stats ) {
        push @vlan_table,
            {
            vlan    => $vlan,
            macaddr => $vlan_stats{$vlan}->{macaddr} || 'na',
            ipaddr  => $vlan_stats{$vlan}->{ipaddr} || 'na',
            };
    }

    my $query_time  = time - Manoc::Utils::str2seconds("60d");
    my @tot_actives = $c->model('ManocDB::Mat')->search(
                                                    {
                                                     'lastseen' => {'>=' => $query_time}
                                                    },
                                                    {
                                                     select  => ['macaddr',{max => 'lastseen'}],
                                                     group_by => 'macaddr',
                                                    }
                                                   );




    my @db_stats = (
        {
            name => "Tot racks",
            val  => $schema->resultset('Rack')->count
        },
        {
            name => "Tot devices",
            val  => $schema->resultset('Device')->count
        },
        {
            name => "Tot interfaces",
            val  => $schema->resultset('IfStatus')->count
        },
        {
            name => "CDP entries",
            val  => $schema->resultset('CDPNeigh')->count
        },
        {
            name => "MAT entries",
            val  => $schema->resultset('Mat')->count
        },
        {
           name => "Active Mat entries",
           val  => scalar(@tot_actives),
        },
        {
            name => "ARP entries",
            val  => $schema->resultset('Arp')->count
        },
    );

    $c->stash(
        disable_pagination => 1,
        vlan_table         => \@vlan_table,
        db_stats           => \@db_stats,
        template           => 'reports/stats.tt',
    );
}

sub ipconflict : Chained('base') : PathPart('ipconflict') : Args(0) {
    my ( $self, $c ) = @_;
    my $schema = $c->model('ManocDB');
    my ( $r, $rs );

    my @conflicts =
        map { ipaddr => Manoc::Utils::unpadded_ipaddr($_->get_column('ipaddr')), count => $_->get_column('count'), },
        $schema->resultset('Arp')->search_conflicts;

    
    
    my @multihomed =
        map { macaddr => $_->get_column('macaddr'), count => $_->get_column('count'), },
        $schema->resultset('Arp')->search_multihomed;

    $c->stash(
        multihomed => \@multihomed,
        conflicts  => \@conflicts,
        template   => 'reports/ipconflict.tt',
    );
}

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
                'me.device', 'me.interface',
                { count => { distinct => 'macaddr' } }, 'ifstatus.description',
            ],

            as       => [ 'device', 'interface', 'count', 'description', ],
            group_by => [ 'device', 'interface' ],
            having => { 'COUNT(DISTINCT(macaddr))' => { '>', 1 } },
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
    $c->stash( template         => 'reports/multihost.tt' );
}

sub unused_ifaces : Chained('base') : PathPart('unused_ifaces') : Args(0) {
    my ( $self, $c ) = @_;

    my $device_id = Manoc::Utils::clean_string( $c->req->param('device') );
    my $days      = Manoc::Utils::clean_string( $c->req->param('days') );

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
        template      => 'reports/unused_ifaces.tt',
    );
}

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
        date        => Manoc::Utils::print_timestamp( $_->last_seen )
    }, @results;

    $c->stash(
        unknown_devices => \@unknown_devices,
        template        => 'reports/unknown_devices.tt'
    );
}

####################################################################

sub device_list : Chained('base') : PathPart('device_list') : Args(0) {
    my ( $self, $c ) = @_;
    my $schema = $c->model('ManocDB');

    my @rs = $schema->resultset('Device')->search(
        undef,
        {
            join     => { rack   => 'building' },
            prefetch => { 'rack' => 'building' },
            order_by => [ 'building.description', 'rack.id' ]
        }
    );
    my @table = map {
        ipaddr       => $_->id->address,
            name     => $_->name,
            vendor   => $_->vendor || 'n/a',
            model    => $_->model || 'n/a',
            os       => ( ( $_->os || 'n/a' ) . ' ' . ( $_->os_ver || '' ) ),
            rack     => $_->rack->id,
            floor    => $_->rack->floor,
            building => $_->rack->building->description,
	    serial   => $_->serial || 'n/a',
    }, @rs;

    $c->stash( table => \@table, template => 'reports/device_list.tt' );
}

sub rack_list : Chained('base') : PathPart('rack_list') : Args(0) {
    my ( $self, $c ) = @_;
    my $schema = $c->model('ManocDB');

    my @rs = $schema->resultset('Rack')->search(
        undef,
        {
            join     => 'building',
            prefetch => 'building',
            order_by => ['me.name' ],
        }
    );
    my @table = map {
            id          => $_->name,
            build_id    => $_->building->name,
            build_name  => $_->building->description,
            floor       => $_->floor,
            notes       => $_->notes,
    }, @rs;

    $c->stash( table => \@table, template => 'reports/rack_list.tt' );
}

####################################################################

sub portsecurity : Chained('base') : PathPart('portsecurity') : Args(0) {
    my ( $self, $c ) = @_;
    my $schema = $c->model('ManocDB');

    my @rs = $schema->resultset('IfStatus')->search(
        { cps_status => 'shutdown' },
        {
            order_by => 'device, interface',
            join     => 'device_info'
        }
    );

    my @table = map {
        id              => $_->device,
            device_name => $_->device_info->name,
            interface   => $_->interface,
            description => $_->description,
            cps_count   => $_->cps_count,
    }, @rs;

    $c->stash( table => \@table, template => 'reports/portsecurity.tt' );

}

####################################################################

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
            having => { 'COUNT(device)' => { '>', 1 } },
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

    $c->stash( multimacs => \@multimacs, template => 'reports/multi_mac.tt' );
}


####################################################################

sub new_devices : Chained('base') : PathPart('new_devices') : Args(0) {
    my ( $self, $c ) = @_;
    my $schema = $c->model('ManocDB');
    my @results;
    my $e;
    my @multimacs;
    my $days       = Manoc::Utils::clean_string( $c->req->param('days') ) || 0 ;
    $days .= 'd' if($days =~ m/\d$/);
    my $query_time = time - Manoc::Utils::str2seconds($days);

    @results = $schema->resultset('Mat')->search(
        { },
        {
            select   => [ 'macaddr', 'device', 'interface', 'firstseen',{ min => 'firstseen' } ],
            as       => [ 'macaddr', 'device', 'interface', 'firstseen','fs'],
            group_by => ['macaddr'],
            having   => { 'MIN(firstseen)' => { '>', $query_time } },
        }
    );

       my @new_devices = map +{
        macaddr      => $_->macaddr,
        device       => $_->device_entry,
        iface        => $_->interface,
        from         => Manoc::Utils::print_timestamp($_->firstseen),
    }, @results;

    $c->stash( new_devs => \@new_devices, template => 'reports/new_devices.tt' );
}







=head1 AUTHOR

Rigo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
