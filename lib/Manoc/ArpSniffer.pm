# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::ArpSniffer;

use Moose;

extends 'Manoc::Script::Daemon';

use Net::Pcap;
use NetPacket::Ethernet qw(:types);
use NetPacket::ARP;

use Manoc::IPAddress::IPv4;

my $DEFAULT_VLAN     = 1;
my $REFRESH_INTERVAL = 600;

has 'pcap_handle' => (
    traits  => ['NoGetopt'],
    is      => 'ro',
    lazy    => 1,
    builder => '_build_pcap_handle'
);

# hash representing set of vlan to exlude
has 'vlan_filter' => (
    traits  => ['NoGetopt'],
    is      => 'ro',
    lazy    => 1,
    builder => '_build_vlan_filter'
);

has 'default_vlan' => (
    traits  => ['NoGetopt'],
    is      => 'ro',
    lazy    => 1,
    builder => '_build_default_vlan'
);

has 'refresh_interval' => (
    traits  => ['NoGetopt'],
    is      => 'ro',
    lazy    => 1,
    builder => '_build_refresh_interval'
);

has 'arp_table' => (
    traits  => ['NoGetopt'],
    is      => 'ro',
    default => sub { {} }
);

after setup_signals => sub {
    my $self = shift;

    # TODO! $SIG{HUP}  = \&update_conf;
    $SIG{QUIT} = sub { $self->leave };
    $SIG{INT}  = sub { $self->leave };
};

before shutdown => sub { shift->leave; };

########################################################################
#                                                                      #
#                  A t t r i b u t e   B u i l d e r s                 #
#                                                                      #
########################################################################

sub _build_pcap_handle {
    my $self = shift;

    my $err;

    my $dev = $self->config->{'ArpSniffer'}->{device};
    if ( !defined($dev) ) {
        $dev = Net::Pcap::lookupdev( \$err );
        if ( defined $err ) {
            $self->log->logdie( 'Unable to determine network device for monitoring - ', $err );
        }
    }

    my $pcap = Net::Pcap::open_live( $dev, 1500, 1, 0, \$err );
    unless ( defined $pcap ) {
        $self->log->logdie("Unable to create packet capture on device $dev - $err");
    }

    $self->log->info("listening on $dev");

    # init filter
    my $filter_str =
        '(arp and not src host 0.0.0.0) || (vlan and arp and not src host 0.0.0.0)';
    my $filter;
    Net::Pcap::compile( $pcap, \$filter, $filter_str, 0, 0 ) &&
        die 'Unable to compile packet capture filter';
    Net::Pcap::setfilter( $pcap, $filter ) &&
        die 'Unable to set packet capture filter';

    return $pcap;
}

sub _build_vlan_filter {
    my $self   = shift;
    my $filter = $self->config->{'ArpSniffer'}->{vlan_filter};

    my $vlan_filter = {};

    return $vlan_filter unless $filter;

    my @filter;
    if ( ref($filter) eq 'ARRAY' ) {
        @filter = @$filter;
    }
    else {
        push @filter, $filter;
    }

    foreach my $vlan (@filter) {
        # syntax check
        $vlan =~ m/^\d+$/o or
            $self->log->logdie("Bad vlan '$vlan' in option vlan_filter.");

        $vlan_filter->{$vlan} = 1;
    }

    $self->log->info( 'filtered vlan: ', join( ',', @filter ) );
    return $vlan_filter;
}

sub _build_default_vlan {
    my $self = shift;

    my $v = $self->config->{'ArpSniffer'}->{vlan};
    defined($v) or $v = $DEFAULT_VLAN;
    $self->log->info("default vlan = $v");
    return $v;
}

sub _build_refresh_interval {
    my $self = shift;
    my $r    = $self->config->{'ArpSniffer'}->{refresh_interval};
    defined($r) or $r = $REFRESH_INTERVAL;
    $self->log->info("refresh interval = $r");
    return $r;
}

########################################################################
#                                                                      #
#                          C a l l b a c k s                           #
#                                                                      #
########################################################################

sub leave {
    my $self = shift;
    $self->log->info("leave: closing pcap");
    Net::Pcap::close( $self->pcap );
    $self->log->info("leave: done");
    exit;
}

sub handle_arp_packets {
    my ( $self, $header, $packet ) = @_;

    my $eth = NetPacket::Ethernet->decode($packet);

    my $type = $eth->{type};
    my $data = $eth->{data};
    my $vlan;

    if ( $type == 0x8100 ) {
        my $tci;
        ( $tci, $type, $data ) = unpack( 'nna*', $data );
        $vlan = $tci & 0x0fff;
    }
    else {
        $vlan = $self->default_vlan;
    }

    # check packet type
    return unless $type == ETH_TYPE_ARP();

    # use vlan filter
    return if $self->vlan_filter->{$vlan};

    my $arp = NetPacket::ARP->decode( $data, $eth );
    my $mac_addr = join( ":", unpack( "(A2)*", $arp->{sha} ) );
    my $ip_addr = join( ".", unpack( "C4", pack( "H*", $arp->{spa} ) ) );

    my $timestamp = time();

    my $arp_table = $self->arp_table;

    my $key   = $ip_addr . '@' . $vlan;
    my $entry = $arp_table->{key};

    return
        if ( $entry &&
        $entry->[0] eq $mac_addr &&
        $timestamp - $entry->[1] < $self->refresh_interval() );

    # update arp table
    $arp_table->{$key} = [ $mac_addr, $timestamp ];
    $self->schema->resultset('Arp')->register_tuple(
        ipaddr    => $ip_addr,
        macaddr   => $mac_addr,
        vlan      => $vlan,
        timestamp => $timestamp,
    );
}

sub main {
    my $self = shift;

    # force init
    $self->schema;
    $self->refresh_interval;
    $self->default_vlan;
    $self->vlan_filter;

    $self->log->info('starting packet capture');

    my $pcap = $self->pcap_handle;
    Net::Pcap::loop( $pcap, -1, \&handle_arp_packets, $self ) ||
        $self->log->logdie('Unable to start packet capture');
}

no Moose;    # Clean up the namespace.
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
