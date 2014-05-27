# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::Netwalker::DeviceUpdater;

# The DeviceUpdater is a bridge between a Netwalker::Source and the
# data in the Manoc DB


use Moose;
with 'Manoc::Logger::Role';

use Manoc::Netwalker::DeviceReport;
use Manoc::Netwalker::Source::SNMP;

use Manoc::IpAddress;

# the Manoc::DB::Device entry associated to this device
has 'entry' => (
    is       => 'ro',
    required => 1
);

has 'timestamp' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1
);

has 'schema' => (
    is       => 'ro',
    required => 1
);

# used to to recognise neighbors and uplinks
has 'device_set' => (
    is       => 'ro',
    isa      => 'HashRef',
    builder => '_build_device_set',

);

# netwalker global config
has 'config' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

# the source for information about the device
has 'source' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_source',
);

has 'report' => (
    is       => 'ro',
    required => 0,
    builder  => '_build_report',
);

has 'uplink_ports' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_uplinks',
);

has 'native_vlan' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_native_vlan',
);

#----------------------------------------------------------------------#
#                                                                      #
#              A t t r i b u t e s   B u i l d e r                     #
#                                                                      #
#----------------------------------------------------------------------#



sub _build_report {
    my $self = shift;
    return Manoc::Netwalker::DeviceReport->new( host => $self->entry->id->address );
}

#----------------------------------------------------------------------#

sub _build_source {
    my $self = shift;

    my $entry = $self->entry;

    # get device community and version or use default
    my $host    = $entry->id->address;
    my $comm    = $entry->snmp_com() || $self->config->{snmp_community};
    my $version = $entry->snmp_ver() || $self->config->{snmp_version};

    my $source = Manoc::Netwalker::Source::SNMP->new(
        host      => $host,
        community => $comm,
        version   => $version,
        ) or return undef;

    unless($source->connect){
        my $msg = "Could not connect to ".$entry->id->address;
        $self->log->error($msg);
        $self->report->add_error($msg);
        return undef;
    }
    $self->report->visited(1);
    return $source;
}

#----------------------------------------------------------------------#

sub _build_native_vlan {
    my $self = shift;

    my $vlan = $self->entry->mat_native_vlan->id || $self->config->{default_vlan};
    return defined($vlan) ? $vlan : 1;
}

#----------------------------------------------------------------------#

sub _build_device_set {
    my $self = shift;

    my @device_ids = $self->schema->resultset('Device')->get_column('id')->all;
    my %device_set = map { Manoc::Utils::unpadded_ipaddr($_) => 1 } @device_ids;
    return \%device_set;
}

#----------------------------------------------------------------------#
sub _build_uplinks {
    my $self = shift;

    my $entry      = $self->entry;
    my $source     = $self->source;
    my $device_set = $self->device_set;

    my %uplinks;

    # get uplink from CDP
    my $neighbors = $source->neighbors;

    while ( my ( $p, $n ) = each(%$neighbors) ) {
        foreach my $s (@$n) {

            next unless $s->{switch};
            next unless $device_set->{ $s->{addr} };

            $uplinks{$p} = 1;
        }
    }

    # get uplinks from DB
    foreach ( $entry->uplinks->all ) {
        $uplinks{ $_->interface } = 1;
    }
    
    return \%uplinks;
}


#----------------------------------------------------------------------#
#                                                                      #
#              A t t r i b u t e    B u i l d e r s                    #
#                                                                      #
#----------------------------------------------------------------------#

sub update_all_info {
    my $self = shift;

    $self->source or return undef;

    $self->log->info( "Performing full update for device ", $self->entry->id->address );

    $self->update_device_entry;
    $self->update_cdp_neighbors;
    $self->update_if_table;
    $self->entry->get_mat() and $self->update_mat;
    $self->entry->get_arp() and $self->update_arp_table;
    #update_dot11;

    #update last visited
    $self->entry->last_visited($self->timestamp);
    $self->entry->update();
    return 1;
}

sub fast_update {
    my $self = shift;

    $self->source or return undef;

    $self->log->info( "Performing fast update for device ", $self->entry->id->address );

    $self->update_cdp_neighbors;
    $self->entry->get_mat() and $self->update_mat;
    $self->entry->get_arp() and $self->update_arp_table;
    #update_dot11;

    #update last visited
    $self->entry->last_visited($self->timestamp);
    $self->entry->update();
    return 1;
}

#----------------------------------------------------------------------#



sub update_device_entry {
    my $self = shift;

    my $source = $self->source;
    my $entry  = $self->entry;

   my $device_info = $source->device_info;

    my $name  = $device_info->{name};
    my $model = $device_info->{model};

    if ( !defined($entry->name) or $entry->name eq "" ) {
        $entry->name($name);
    }
    elsif ( $name ne $entry->name ) {
        my $msg = "Name mismatch " . $entry->name . " $name";
        $self->log->warn($msg);
        $self->report->add_warning($msg);
    }

    if ( !defined($entry->model) or $entry->model eq "" ) {
        $entry->model($model);
    }
    elsif ( $model ne $entry->model ) {
        my $msg = "Model mismatch " . $entry->model . " $model";
        $self->log->warn($msg);
        $self->report->add_warning($msg);
    }

    $entry->set_column( os     => $device_info->{os} );
    $entry->set_column( os_ver => $device_info->{os_ver} );
    $entry->set_column( vendor => $device_info->{vendor} );
    $entry->set_column( serial => $device_info->{serial} );

    $entry->vtp_domain( $source->vtp_domain );
    $entry->boottime( $source->boottime );

    $entry->offline(0);
    $entry->update;
}

#----------------------------------------------------------------------#

sub update_cdp_neighbors {
    my $self = shift;

    my $source = $self->source;
    my $entry  = $self->entry;
    my $schema = $self->schema;
    my $neighbors = $source->neighbors;
    my $new_dev     = 0;
    my $cdp_entries = 0;
    
    while ( my ( $p, $n ) = each(%$neighbors) ) {
        foreach my $s (@$n) {
            
            my $from_dev_obj = $entry->id;
            my $to_dev_obj   = Manoc::IpAddress->new($s->{addr});

            my @cdp_entries = $self->schema->resultset('CDPNeigh')->search(
                {
                    from_device    => $from_dev_obj->padded,
                    from_interface => $p,
                    to_device      => $to_dev_obj,
                    to_interface   => $s->{port},
                }
            );

            
            unless ( scalar(@cdp_entries) ) {
                
                my $temp_obj = Manoc::IpAddress->new($entry->id->address);
                
                $self->schema->resultset('CDPNeigh')->create(
                {
                    from_device    => $temp_obj->padded,
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
                $self->report->add_warning("New neighbor ".$s->{addr}." at ".$entry->id->address);
                next;
            }
            my $link = $cdp_entries[0];
            $link->last_seen($self->timestamp);
            $link->update;
            $cdp_entries++; 
        }
    }
    $self->report->cdp_entries($cdp_entries);
    $self->report->new_devices($new_dev);

}

#----------------------------------------------------------------------#

sub update_if_table {
    my $self = shift;

    my $source       = $self->source;
    my $entry        = $self->entry;
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
    my $entry  = $self->entry;
    my $schema = $self->schema;
    
    my $uplinks = $self->uplink_ports;
    $self->log->debug( "device uplinks: ", join( ",", keys %$uplinks ) );
 
    my $timestamp = $self->timestamp;
    my $device_id = $entry->id;

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

            my @mat_entries = $self->schema->resultset('Mat')->search(
                {
                    macaddr   => $m,
                    device    => $device_id,
                    interface => $p,
                    archived  => 0,
                    vlan      => $vlan,
                }
            );
            if ( scalar(@mat_entries) > 1 ) {
                my $msg = "More than one non archived entry for ".$entry->name.",$m,$p";
                $self->log->error($msg );
                $self->report->add_error($msg );
                next;
            }
            $mat_count++;
            my $create_new_entry = 0;
            if (@mat_entries) {
                my $entry = $mat_entries[0];

                # check for a vlan change
                if ( $entry->vlan() != $vlan ) {
                    $entry->archived(1);
                    $entry->update();
                    $create_new_entry = 1;
                }
                else {
                    $entry->lastseen($timestamp);
                    $entry->update();
                }
            }
            else {
                $create_new_entry = 1;
            }

            if ($create_new_entry) {
                $schema->resultset('Mat')->update_or_create(
                    {
                        macaddr   => $m,
                        device    => $device_id,
                        interface => $p,
                        firstseen => $timestamp,
                        lastseen  => $timestamp,
                        vlan      => $vlan,
                        archived  => 0,
                    }
                );
            }

        }    # end of entries loop

    }    # end of mat loop

    $self->report->mat_entries($mat_count);
}

#----------------------------------------------------------------------#

sub update_vtp_database {
    my $self = shift;

    my $source = $self->source;
    my $entry  = $self->entry;

    my $vlan_db = $source->vtp_database;

    $self->log->info( "getting vtp info from ", $entry->id->address );
    if ( !defined($vlan_db) ) {
        $self->log->error("cannot retrieve vtp info");
        $self->report->add_error("cannot retrieve vtp info");
        return;
    }

    $self->report->add_warning("Vtp Vlan DB up to date");

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
    my $vtp_last_update_entry =
      $self->schema->resultset('System')->find("netwalker.vtp_update");
    $vtp_last_update_entry->value($self->timestamp);
    $vtp_last_update_entry->update();

}

sub update_arp_table {
    my $self = shift;

    my $source   = $self->source;
    my $entry    = $self->entry;
    my $timestamp= $self->timestamp;
    my $vlan     = defined($entry->vlan_arpinfo) ? $entry->vlan_arpinfo->id : $self->config->{default_vlan};
    my $arp_table= $source->arp_table;
    my $arp_count= 0;

    $self->log->debug("Fetching arp table from ",$self->entry->id->address);
    
    my ($ip_addr, $mac_addr);
    while (($ip_addr, $mac_addr) = each(%$arp_table)) {
        $self->log->debug(sprintf("Arp table: %15s at %17s\n", $ip_addr, $mac_addr));

        my $ip_obj =  Manoc::IpAddress->new( $ip_addr  );
	my @entries = $self->schema->resultset('Arp')->search({
	    ipaddr	=> $ip_obj,
	    macaddr	=> $mac_addr,
	    vlan	=> $vlan,
	    archived => 0
	    });
    
        if(scalar(@entries) > 1) {
            $self->log->error("More than one non archived entry for $ip_addr,$mac_addr");
            $self->report->add_error("More than one non archived entry for $ip_addr,$mac_addr");
        }
        $arp_count++;
	if (@entries) {
	    my $entry = $entries[0];	
	    $entry->lastseen($timestamp);
	    $entry->update();
	} else {
	    $self->schema->resultset('Arp')->create({
		ipaddr    => $ip_obj,
		macaddr   => $mac_addr,
		firstseen => $timestamp,
		lastseen  => $timestamp,
		vlan      => $vlan,
		archived  => 0
	    });
	}
     }
    $self->report->arp_entries($arp_count);
}

#----------------------------------------------------------------------#

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
