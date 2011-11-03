# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

# A frontend for SNMP::Info

package Manoc::Netwalker::Source::SNMP;
use Moose;

with 'Manoc::Netwalker::Source';
with 'Manoc::Logger::Role';

use Carp;
use SNMP::Info;
use Try::Tiny;

has 'host' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'community' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'public'
);

has 'version' => (
    is      => 'ro',
    isa     => 'Str',
    default => '1',
);

has 'is_subrequest' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0
);

has 'snmp_info' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_snmp_info',
);

#-----------------------------------------------------------------------#
sub _build_snmp_info {
    my $self = shift;
    my $info;

    my %snmp_info_args = (
        # Auto Discover more specific Device Class
        AutoSpecify => 1,

        Debug => $ENV{SNMPINFO_DEBUG},

        # The rest is passed to SNMP::Session
        DestHost  => $self->host,
        Community => $self->community,
        Version   => $self->version,
    );

    try{
        $info = new SNMP::Info(%snmp_info_args);
    } catch{
        my $msg = "Could not connect to ".$self->host." .$_";
        $self->log->error( $msg );
        return undef;
    };

    unless ($info) {
        $self->log->error( "Could not connect to ", $self->host );
        return undef;
    }
    # guessing special devices...
    my $class = _guess_snmp_info_class($info);
    return $info unless defined $class;

    $self->log->debug("ovverriding SNMPInfo class: $class");

    eval "require $class";
    if ($@) {
        croak "Manoc::SNMPInfo::try_specify() Loading $class failed. $@\n";
    }

    my $args    = $self->{snmp_info_args};
    my $session = $info->session();
    my $sub_obj = $class->new(
        %$args,
        Session     => $session,
        AutoSpecify => 0
    );

    unless ($sub_obj) {
        $self->log->error("Could not reconnect with new class ($class)");
        return;
    }

    return $sub_obj;

}

sub _guess_snmp_info_class {
    my $info = shift;

    my $class;

    my $desc = $info->description() || 'undef';
    $desc =~ s/[\r\n\l]+/ /g;

    $desc =~ /Cisco IOS Software, C1240 / and
        $class = "SNMP::Info::Layer2::Aironet1240";

    $desc =~ /Cisco.*?IOS.*?CIGESM/ and
        $class = "SNMP::Info::Layer3::C3550";

    $desc =~ /Cisco.*?IOS.*?C2960/ and
      $class = "SNMP::Info::Layer3::C6500";


    #broken
    #$desc =~ /Cisco Controller/ and
    #    $class = "SNMP::Info::Layer2::CiscoWCS";

    return unless $class;

    # check if snmp::info::specify did it right
    return if $class eq $info->class;

    return $class;
}

#------------------------------------------------------------------------#

# Get CDP Neighbor info
sub _build_neighbors {
    my $self = shift;
    my $host = $self->host;

    my %res;

    my $info           = $self->snmp_info;
    my $interfaces     = $info->interfaces();
    my $c_if           = $info->c_if();
    my $c_ip           = $info->c_ip();
    my $c_port         = $info->c_port();
    my $c_capabilities = $info->c_capabilities();

    foreach my $neigh ( keys %$c_if ) {
        my $port = $interfaces->{ $c_if->{$neigh} };
        defined($port) or next;

        my $neigh_ip   = $c_ip->{$neigh}   || "no-ip";
        my $neigh_port = $c_port->{$neigh} || "";

        my $cap = $c_capabilities->{$neigh};
        $self->log->debug("$host/$port connected to $neigh_ip ($cap)");
        $cap = pack( 'B*', $cap );
        my $entry = {
            port   => $neigh_port,
            addr   => $neigh_ip,
            bridge => vec( $cap, 2, 1 ),
            switch => vec( $cap, 4, 1 ),
        };
        push @{ $res{$port} }, $entry;
    }
    return \%res;
}

#------------------------------------------------------------------------#

sub _build_mat {
    my $self = shift;
    my $info = $self->snmp_info || croak "SNMP source not initialized!";

    my $interfaces = $info->interfaces();
    my $fw_mac     = $info->fw_mac();
    my $fw_port    = $info->fw_port();
    my $fw_status  = $info->fw_status();
    my $bp_index   = $info->bp_index();

    my ( $status, $mac, $bp_id, $iid, $port );
    my $mat = {};
    foreach my $fw_index ( keys %$fw_mac ) {
        $status = $fw_status->{$fw_index};
        next if defined($status) and $status eq 'self';
        $mac   = $fw_mac->{$fw_index};
        $bp_id = $fw_port->{$fw_index};
        next unless defined $bp_id;
        $iid = $bp_index->{$bp_id};
        next unless defined $iid;
        $port = $interfaces->{$iid};

        $mat->{default}->{$mac} = $port;
    }

    if ( $info->cisco_comm_indexing() && !$self->is_subrequest ) {
        $self->log->debug("Device supports Cisco community string indexing.");

        my $v_name = $info->v_name() || {};
        my $i_vlan = $info->i_vlan() || {};

        # Get list of VLANs currently in use by ports
        my %vlans;
        foreach my $key ( keys %$i_vlan ) {
            my $vlan = $i_vlan->{$key};
            $vlans{$vlan}++;
        }

        # For each VLAN: connect, get mat and merge
        while ( my ( $vid, $vlan_name ) = each(%$v_name) ) {
            next if $vlan_name eq "default";
            $vlan_name ||= '(Unnamed)';

            # VLAN id comes as 1.142 instead of 142
            my $vlan = $vid;
            $vlan =~ s/^\d+\.//;

            # Only use VLAN in use by ports
            #  but check to see if device serves us that list first
            if ( scalar( keys(%$i_vlan) ) && !defined( $vlans{$vlan} ) ) {
                next;
            }

            $self->log->debug(" VLAN: $vlan - $vlan_name");
            my $vlan_comm = $self->community . '@' . $vlan;
            my $subreq    = Manoc::Netwalker::Source::SNMP->new(
                host          => $self->host,
                community     => $vlan_comm,
                version       => $self->version,
                is_subrequest => 1
            );
            next unless defined($subreq);
            # merge mat
            $subreq->mat and $mat->{$vlan} = $subreq->mat->{default};
        }
    }    # end of cisco vlan comm indexing

    return $mat;
}

#----------------------------------------------------------------------#

sub vtp_domain {
    my $self = shift;
    my $info = $self->snmp_info;

    my $vtpdomains = $info->vtp_d_name();

    if ( defined $vtpdomains and scalar( values(%$vtpdomains) ) ) {
        return ( values(%$vtpdomains) )[-1];
    }
    return undef;
}

sub vtp_database {
    my $self = shift;
    my $info = $self->snmp_info;

    my $vlan = $info->v_name();
    defined($vlan) or return undef;

    my %vlan_db;

    while ( my ( $iid, $name ) = each(%$vlan) ) {
        my $id_temp = $iid;
        $id_temp =~ s/^\d+.//;

        $vlan_db{$id_temp} = $name;
    }

    return \%vlan_db;
}

#----------------------------------------------------------------------#

sub connect {
    my $self = shift;
    return defined( $self->snmp_info ) ? 1 : 0;
}

#----------------------------------------------------------------------#

sub boottime {
    my $self = shift;
    return time() - $self->snmp_info->uptime() / 100;
}

#----------------------------------------------------------------------#

sub device_info {
    my $self = shift;
    my $info = $self->snmp_info or return undef;

    return {
        name   => $info->name,
        model  => $info->model,
        os     => $info->os,
        os_ver => $info->os_ver,
        vendor => $info->vendor
    };

}

#----------------------------------------------------------------------#

sub _build_ifstatus_table {
    my $self = shift;

    my $info = $self->snmp_info;

    # get interface info
    my $interfaces     = $info->interfaces();
    my $i_iname        = $info->i_name();
    my $i_up           = $info->i_up();
    my $i_up_admin     = $info->i_up_admin();
    my $i_duplex       = $info->i_duplex();
    my $i_duplex_admin = $info->i_duplex_admin();
    my $i_speed        = $info->i_speed();
    my $i_vlan         = $info->i_vlan();
    my $i_stp_state    = $info->i_stp_state();

    my $cps_i_enable = $info->cps_i_enable;
    my $cps_i_status = $info->cps_i_status;
    my $cps_i_count  = $info->cps_i_count;

    my %ifstatus;

INTERFACE:
    foreach my $iid ( keys %$interfaces ) {
        my $port = $interfaces->{$iid};

        unless ( defined $port and length($port) ) {
            $self->log->debug("Ignoring $iid (no port mapping)");
            next INTERFACE;
        }

        $self->log->debug("Getting status for $port");

        my %interface;
        $interface{description}  = $i_iname->{$iid};
        $interface{up}           = $i_up->{$iid};
        $interface{up_admin}     = $i_up_admin->{$iid};
        $interface{duplex}       = $i_duplex->{$iid};
        $interface{duplex_admin} = $i_duplex_admin->{$iid};
        $interface{speed}        = $i_speed->{$iid};
        $interface{vlan}         = $i_vlan->{$iid};
        $interface{stp_state}    = $i_stp_state->{$iid};

        $interface{cps_enable} = $cps_i_enable->{$iid};
        $interface{cps_status} = $cps_i_status->{$iid};
        $interface{cps_count}  = $cps_i_count->{$iid};

        $ifstatus{$port} = \%interface;
    }

    return \%ifstatus;
}

#----------------------------------------------------------------------#

sub _build_arp_table {
    my $self = shift;

    my $info = $self->snmp_info;
    my %arp_table;

    my $at_paddr   = $info->at_paddr();
    my $at_netaddr = $info->at_netaddr();

    while ( my ( $k, $v ) = each(%$at_paddr) ) {
        my $ip_addr  = $at_netaddr->{$k};
        my $mac_addr = $v;

        # broadcast IP will show up in the node table.
        next if uc($mac_addr) eq 'FF:FF:FF:FF:FF:FF';

        # Skip Passport 8600 CLIP MAC addresses
        next if uc($mac_addr) eq '00:00:00:00:00:01';

        # Skip VRRP addresses
        next if $mac_addr =~ /^00:00:5e:00:/i;

        $arp_table{$ip_addr} = $mac_addr;
    }

    return \%arp_table;
}

#

no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
