# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

# A frontend for SNMP::Info

package Manoc::Manifold::SNMP::Info;
use Moose;

with 'Manoc::ManifoldRole::Base';
with 'Manoc::Logger::Role';

use SNMP::Info;
use Carp qw(croak);
use Try::Tiny;

has 'community' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_community',
);

has 'version' => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => '1',
    builder => '_build_version',
);

has 'is_subrequest' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0
);

has 'snmp_info' => (
    is     => 'ro',
    isa    => 'Object',
    writer => '_set_snmp_info',
);

has 'mat_force_vlan' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_mat_force_vlan'
);

sub _build_community {
    my $self = shift;

    return $self->credentials->{snmp_community} || 'public';
}

sub _build_version {
    my $self = shift;
    my $version = $self->credentials->{snmp_version} || 2;
    $version eq '2c' and $version = 2;

    return $version;
}

sub _build_mat_force_vlan {
    my $self = shift;
    return $self->extra_params->{mat_force_vlan};
}

sub connect {
    my ($self) = @_;
    my $opts = shift || {};

    my $info;

    my $snmp_options;
    $snmp_options = $self->extra_params->{snmp_options} || {};
    my %snmp_info_args = (
        # Auto Discover more specific Device Class
        AutoSpecify => 1,

        Debug => $ENV{MANOC_DEBUG_SNMPINFO},

        # The rest is passed to SNMP::Session
        DestHost  => $self->host,
        Community => $self->community,
        Version   => $self->version,
        %$snmp_options,
    );

    try {
        $info = SNMP::Info->new(%snmp_info_args);
    }
    catch {
        my $msg = "Could not connect to " . $self->host . " .$_";
        $self->log->error($msg);
        return undef;
    };

    unless ($info) {
        $self->log->error( "Could not connect to ", $self->host );
        return undef;
    }

    # guessing special devices...
    my $class = _guess_snmp_info_class($info);
    if ( defined($class) ) {
        $self->log->debug("ovverriding SNMPInfo class: $class");

        eval "require $class";
        if ($@) {
            croak "Loading $class failed. $@\n";
        }

        my $session = $info->session();
        $info = $class->new(
            Session     => $session,
            AutoSpecify => 0
        );

        unless ($info) {
            $self->log->error("Could not reconnect with new class ($class)");
            return undef;
        }
    }
    $self->_set_snmp_info($info);
    return 1;
}

sub _guess_snmp_info_class {
    my $info = shift;

    my $class;

    my $desc = $info->description() || 'undef';
    $desc =~ s/[\r\n\l]+/ /g;

    $desc =~ /Cisco.*?IOS.*?CIGESM/ and
        $class = "SNMP::Info::Layer3::C3550";

    $desc =~ /Cisco.*?IOS.*?C2960/ and
        $class = "SNMP::Info::Layer3::C3550";

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
    my $c_capabilities = $info->cdp_cap();
    my $c_id           = $info->c_id();
    my $c_platform     = $info->c_platform();

    foreach my $neigh ( keys %$c_if ) {
        my $port = $interfaces->{ $c_if->{$neigh} };
        defined($port) or next;

        my $neigh_ip    = $c_ip->{$neigh}       || "0.0.0.0";
        my $neigh_port  = $c_port->{$neigh}     || "";
        my $neigh_id    = $c_id->{$neigh}       || "";
        my $neigh_model = $c_platform->{$neigh} || "";

        my %cap = map {$_ => 1} @{$c_capabilities->{$neigh}};
        $cap{'Switch'} and $self->log->debug("$host/$port connected to $neigh_ip");

        my $entry = {
            port        => $neigh_port,
            addr        => $neigh_ip,
            type        => \%cap,
            remote_id   => $neigh_id,
            remote_type => $neigh_model,
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

        if ( defined( $self->mat_force_vlan ) ) {
            if ( ref( $self->mat_force_vlan ) eq 'ARRAY' ) {
                foreach my $v ( @{ $self->mat_force_vlan } ) {
                    $v =~ m/^\d+$/o and $vlans{$v}++;
                }
            }
            else {
                $self->mat_force_vlan =~ m/^\d+$/o and
                    $vlans{ $self->mat_force_vlan }++;
            }
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
            #prepare credentials with the new community string
            my $new_credentials = {
                snmp_community => $self->community . '@' . $vlan,
                version        => $self->version,
            };

            my $subreq = Manoc::Manifold::SNMP->new(
                host          => $self->host,
                credentials   => $new_credentials,
                is_subrequest => 1
            );
            next unless defined($subreq);
            $subreq->connect();
            # merge mat
            $subreq->mat and $mat->{$vlan} = $subreq->mat->{default};
        }
    }    # end of cisco vlan comm indexing

    return $mat;
}

#----------------------------------------------------------------------#

sub _build_vtp_domain {
    my $self = shift;
    my $info = $self->snmp_info;

    my $vtpdomains = $info->vtp_d_name();

    if ( defined $vtpdomains and scalar( values(%$vtpdomains) ) ) {
        return ( values(%$vtpdomains) )[-1];
    }
    return undef;
}

sub _build_vtp_database {
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

sub _build_boottime {
    my $self = shift;
    return time() - int( $self->snmp_info->uptime() / 100 );
}

sub _build_name {
    my $self = shift;
    my $info = $self->snmp_info;
    return $info->name;
}

sub _build_model {
    my $self = shift;
    my $info = $self->snmp_info;
    return $info->model;
}

sub _build_os {
    my $self = shift;
    my $info = $self->snmp_info;
    return $info->os;
}

sub _build_os_ver {
    my $self = shift;
    my $info = $self->snmp_info;
    return $info->os_ver;
}

sub _build_vendor {
    my $self = shift;
    my $info = $self->snmp_info;
    return $info->vendor;
}

sub _build_serial {
    my $self = shift;
    my $info = $self->snmp_info;
    return $info->serial;
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
