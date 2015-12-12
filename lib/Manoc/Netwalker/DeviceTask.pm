# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::Netwalker::DeviceTask;

use Moose;
with 'Manoc::Logger::Role';

use Manoc::Netwalker::TaskReport;
use Manoc::Manifold;

use Manoc::IPAddress::IPv4;

has 'device_id' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1
);

has 'schema' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1
);

has 'config' => (
    is       => 'ro',
    isa      => 'Manoc::Netwalker::Config',
    required => 1
);

has 'device_entry' => (
    is       => 'ro',
    isa      => 'Maybe[Object]',
    lazy     => 1,
    builder  => '_build_device_entry',
);

has 'nwinfo' => (
    is       => 'ro',
    isa      => 'Object',
    lazy     => 1,
    builder  => '_build_nwinfo',
);

has 'credentials' => (
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    builder  => '_build_credentials',
);

has 'timestamp' => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { time },
);

# a set of all mng_address known to Manoc
# used to to discover neighbors and uplinks
has 'device_set' => (
    is       => 'ro',
    isa      => 'HashRef',
    builder => '_build_device_set',
);

# the source for information about the device
has 'source' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_source',
);

has 'task_report' => (
    is       => 'ro',
    required => 0,
    builder  => '_build_task_report',
);

has 'uplinks' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_uplinks',
);

has 'native_vlan' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_native_vlan',
);

has 'arp_vlan' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_arp_vlan',
);


#----------------------------------------------------------------------#
#                                                                      #
#              A t t r i b u t e s   B u i l d e r                     #
#                                                                      #
#----------------------------------------------------------------------#


sub _build_arp_vlan {
    my $self = shift;

    my $vlan = $self->nwinfo->arp_vlan->id
        || $self->config->default_vlan;
    return defined($vlan) ? $vlan : 1;
}

sub _build_credentials {
    my $self = shift;

    my $credentials = $self->nwinfo->get_credentials_hash;
    $credentials->{snmp_community} ||= $self->config->snmp_community;
    $credentials->{snmp_version}   ||= $self->config->snmp_version;

    return $credentials;
}

sub _build_device_entry {
    my $self = shift;
    my $device_id = $self->device_id;
    
    return $self->schema->resultset('Device')->find($self->device_id);
}

sub _build_device_set {
    my $self = shift;

    # columns are not inflated
    my @addresses = $self->schema->resultset('Device')->get_column('mng_address')->all;
    my %addr_set = map {
        Manoc::IPAddress::IPv4->new($_)->unpadded => 1
    } @addresses;
    return \%addr_set;
}


sub _build_native_vlan {
    my $self = shift;

    my $vlan = $self->nwinfo->mat_native_vlan->id
        || $self->config->default_vlan;
    return defined($vlan) ? $vlan : 1;
}

sub _build_nwinfo {
    my $self = shift;

    return $self->device_entry->netwalker_info;
}

sub _build_source {
    my $self = shift;

    my $entry  = $self->device_entry;
    my $nwinfo = $self->nwinfo;

    my $host   = $entry->mng_address->unpadded;
    my $mat_force_vlan = $self->config->mat_force_vlan;

    my $manifold_name = $nwinfo->manifold;
    $self->log->debug("Using Manifold $manifold_name");
    
    my $source = Manoc::Manifold->new_manifold(
        $manifold_name,
        host         => $host,
        credentials  => $self->credentials,
        extra_params => {
            mat_force_vlan => $mat_force_vlan,
        }
    );
    if ( !$source ) {
        $self->log->error("Cannot create manifold $manifold_name");
    }

    $source->connect() or return undef;
    return $source;
}

sub _build_task_report {
    my $self = shift;

    $self->device_entry or return undef;
    my $device_address = $self->device_entry->mng_address->address;
    return Manoc::Netwalker::TaskReport->new( host => $device_address );
}

sub _build_uplinks {
    my $self = shift;

    my $entry      = $self->device_entry;
    my $source     = $self->source;
    my $device_set = $self->device_set;

    my %uplinks;

    # get uplink from CDP
    my $neighbors = $source->neighbors;

    # filter CDP links
    while ( my ( $p, $n ) = each(%$neighbors) ) {
        foreach my $s (@$n) {

            # only links to a switch
            next unless $s->{switch};

            # only links to a kwnown device
            next unless $device_set->{ $s->{addr} };

            $uplinks{$p} = 1;
        }
    }

    # get uplinks from DB and merge them
    foreach ( $entry->uplinks->all ) {
        $uplinks{ $_->interface } = 1;
    }

    return \%uplinks;
}


#----------------------------------------------------------------------#
#                                                                      #
#                       D a t a   u p d a t e                          #
#                                                                      #
#----------------------------------------------------------------------#

sub update {
    my $self = shift;

    # check if there is a device object in the DB
    my $entry  = $self->device_entry;
    unless($entry){
        $self->log->error("Cannot find device id", $self->device_id);
        return undef;
    }

    # load netwalker info from DB
    my $nwinfo = $self->nwinfo;
    unless($nwinfo){
        $self->log->error("No netwalker info for device", $entry->name);
        return undef;
    }

    
    # try to connect and update nwinfo accordingly
    $self->log->info( "Connecting to device ", $entry->name, " ", $entry->mng_address );
    if ( ! $self->source ) {
        # TODO update nwinfo with connection messages
        $self->nwinfo->offline(1);
        return undef;
    }
    $nwinfo->last_visited($self->timestamp);
    $nwinfo->offline(0);

    $self->update_device_info;
    
    # if full_update_interval is elapsed update interface table
    my $full_update_interval = $self->config->full_update_interval;
    my $elapsed_full_update  = $self->timestamp - $nwinfo->last_full_update;
    if ($elapsed_full_update >= $full_update_interval) {
        $self->update_if_table;

        # update nwinfo
        $nwinfo->last_full_update($self->timestamp);
    }

    # always update CPD info
    $self->update_cdp_neighbors;

    # update required information
    $nwinfo->get_mat   and $self->update_mat;
    $nwinfo->get_arp   and $self->update_arp_table;
    $nwinfo->get_vtp   and $self->update_vtp_database;
    $nwinfo->get_dot11 and $self->update_dot11;


    # TODO update nwinfo
    $nwinfo->update();
    return 1;
}


#----------------------------------------------------------------------#


sub update_device_info {
    my $self = shift;

    my $source = $self->source;
    my $entry  = $self->device_entry;

    my $name  = $source->name;
    my $model = $source->model;

    if ( !defined($entry->name) or $entry->name eq "" ) {
        $entry->name($name);
    }
    elsif ( defined($name) && $name ne $entry->name ) {
        my $msg = "Name mismatch " . $entry->name . " $name";
        $self->log->warn($msg);
        $self->task_report->add_warning($msg);
    }

    if ( !defined($entry->model) or $entry->model eq "" ) {
        $entry->model($model);
    }
    elsif ( $model ne $entry->model ) {
        my $msg = "Model mismatch " . $entry->model . " $model";
        $self->log->warn($msg);
        $self->task_report->add_warning($msg);
    }

    $entry->os( $source->os );
    $entry->os_ver( $source->os_ver );
    $entry->vendor( $source->vendor );
    $entry->serial( $source->serial );

    $entry->vtp_domain( $source->vtp_domain );
    $entry->boottime( $source->boottime || 0);

    $entry->update;
}

#----------------------------------------------------------------------#

sub update_cdp_neighbors {
    my $self = shift;

    my $source = $self->source;
    my $entry  = $self->device_entry;
    my $schema = $self->schema;
    my $neighbors = $source->neighbors;
    my $new_dev     = 0;
    my $cdp_entries = 0;

    while ( my ( $p, $n ) = each(%$neighbors) ) {
        foreach my $s (@$n) {
            my $from_dev_id = $entry->id;
            my $to_dev_obj   = Manoc::IPAddress::IPv4->new($s->{addr});

            my @cdp_entries = $self->schema->resultset('CDPNeigh')->search(
                {
                    from_device    => $from_dev_id,
                    from_interface => $p,
                    to_device      => $to_dev_obj->padded,
                    to_interface   => $s->{port},
                }
            );

            unless ( scalar(@cdp_entries) ) {
                $self->schema->resultset('CDPNeigh')->create(
                    {
                        from_device    => $from_dev_id,
                        from_interface => $p,
                        to_device      => $to_dev_obj,
                        to_interface   => $s->{port},
                        remote_id      => $s->{remote_id},
                        remote_type    => $s->{remote_type},
                        last_seen      => $self->timestamp,
                    }
                ); 
                $new_dev++;
                $cdp_entries++; 
                $self->task_report->add_warning("New neighbor ".$s->{addr}." at ".$entry->name);
                next;
            }
            my $link = $cdp_entries[0];
            $link->last_seen($self->timestamp);
            $link->update;
            $cdp_entries++; 
        }
    }
    $self->task_report->cdp_entries($cdp_entries);
    $self->task_report->new_devices($new_dev);
}

#----------------------------------------------------------------------#

sub update_if_table {
    my $self = shift;

    my $source       = $self->source;
    my $entry        = $self->device_entry;
    my $iface_filter = $self->config->{iface_filter};

    my $ifstatus_table = $source->ifstatus_table;

    # delete old infos
    $entry->ifstatus()->delete;
    # update
    foreach my $port ( keys %$ifstatus_table ) {
        $iface_filter && lc($port) =~ /^(vlan|null|unrouted vlan)/o and next;
        my $ifstatus = $ifstatus_table->{$port};
        $entry->add_to_ifstatus(
            {
                interface => $port,
                %$ifstatus
            }
        );
    }
}

#----------------------------------------------------------------------#

sub update_mat {
    my $self = shift;

    my $source = $self->source;
    my $entry  = $self->device_entry;
    my $schema = $self->schema;
    
    my $uplinks = $self->uplinks;
    $self->log->debug( "device uplinks: ", join( ",", keys %$uplinks ) );
 
    my $timestamp = $self->timestamp;
    my $device_id = $self->device_id;

    my $ignore_portchannel = $self->config->{ignore_portchannel};

    my $mat = $source->mat() or return;

    my $mat_count = 0;

    while ( my ( $vlan, $entries ) = each(%$mat) ) {
        $self->log->debug("updating mat vlan $vlan");

        if( $vlan eq 'default' ) {
            $vlan = $self->native_vlan;
        }
        while ( my ( $m, $p ) = each %$entries ) {
            next if $uplinks->{$p};
            next if $ignore_portchannel && lc($p) =~ /^port-channel/;

            $self->schema->resultset('Mat')->register_tuple(
                macaddr   => $m,
                device    => $device_id,
                interface => $p,
                timestamp => $timestamp,
                vlan      => $vlan,
            );

        }    # end of entries loop

    }    # end of mat loop

    $self->task_report->mat_entries($mat_count);
}

#----------------------------------------------------------------------#

sub update_vtp_database {
    my $self = shift;

    my $source = $self->source;
    my $entry  = $self->device_entry;

    my $vlan_db = $source->vtp_database;

    $self->log->info( "getting vtp info from ", $entry->mng_address );
    if ( !defined($vlan_db) ) {
        $self->log->error("cannot retrieve vtp info");
        $self->task_report->add_error("cannot retrieve vtp info");
        return;
    }

    $self->task_report->add_warning("Vtp Vlan DB up to date");

    my $rs = $self->schema->resultset('VlanVtp');
    $rs->delete();
    while ( my ( $id, $name ) = each(%$vlan_db) ) {
        $rs->find_or_create(
            {
                'id'   => $id,
                'name' => $name
            }
        );
    }
    my $vtp_last_update =
      $self->schema->resultset('System')->find("netwalker.vtp_update");
    $vtp_last_update->value($self->timestamp);
    $vtp_last_update->update();

}

sub update_arp_table {
    my $self = shift;

    my $source    = $self->source;
    my $entry     = $self->device_entry;
    my $timestamp = $self->timestamp;
    my $vlan      = $self->arp_vlan;


    $self->log->debug("Fetching arp table ");
    my $arp_table = $source->arp_table;

    # TODO log error
    $arp_table or return;
    
    my $arp_count = 0;
    my ($ip_addr, $mac_addr);
    while (($ip_addr, $mac_addr) = each(%$arp_table)) {
        $self->log->debug(sprintf("Arp table: %15s at %17s\n", $ip_addr, $mac_addr));

        $self->schema->resultset('Arp')->register_tuple(
	    ipaddr	=> $ip_addr,
	    macaddr	=> $mac_addr,
	    vlan	=> $vlan,
            timestamp   => $timestamp,
        );
        $arp_count++;
    }

    $self->task_report->arp_entries($arp_count);
}

sub update_config {
    my $self = shift;

    my $timestamp = $self->timestamp;

    my $config_text = $self->backup_source->get_config();
    $self->device_entry->update_config($config_text, $timestamp);
}

#----------------------------------------------------------------------#

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
