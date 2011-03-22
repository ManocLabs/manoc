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
    required => 1,
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
    builder => '_build_source',
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

sub _build_source {
    my $self = shift;

    my $entry = $self->entry;

    # get device community and version or use default
    my $host    = $entry->id;
    my $comm    = $entry->snmp_com() || $self->config->{snmp_community};
    my $version = $entry->snmp_ver() || $self->config->{snmp_version};

    my $source = Manoc::Netwalker::Source::SNMP->new(
        host      => $host,
        community => $comm,
        version   => $version,
        ) or
        return undef;
    $source->connect or return undef;

    $self->report->visited(1);
    return $source;
}

#----------------------------------------------------------------------#

sub _build_report {
    my $self = shift;
    return Manoc::Netwalker::DeviceReport->new( host => $self->entry->id );
}

#----------------------------------------------------------------------#

sub _build_native_vlan {
    my $self = shift;

    my $vlan = $self->config->{default_vlan};
    return defined($vlan) ? $vlan : 1;
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

    $self->log->info( "updating all device info for ", $self->entry->id );
    $self->update_device_entry;
}

#----------------------------------------------------------------------#

sub update_device_entry {
    my $self = shift;

    my $source = $self->source;
    my $entry  = $self->entry;

    my $device_info = $source->device_info;

    my $name  = $device_info->{name};
    my $model = $device_info->{model};

    if ( $entry->name eq "" ) {
        $entry->name($name);
    }
    elsif ( $name ne $entry->name ) {
        my $msg = "Name mismatch " . $entry->name . " $name";
        $self->log->warning($msg);
        $self->report->add_warning($msg);
    }

    if ( $entry->model eq "" ) {
        $entry->model($model);
    }
    elsif ( $model ne $entry->model ) {
        my $msg = "Model mismatch " . $entry->model . " $model";
        $self->log->warning($msg);
        $self->report->add_warning($msg);
    }

    $entry->set_column( os     => $device_info->{os} );
    $entry->set_column( os_ver => $device_info->{os_ver} );
    $entry->set_column( vendor => $device_info->{vendor} );

    $entry->vtp_domain( $source->vtp_domain );
    $entry->boottime( $source->boottime );

    $entry->offline(0);
    $entry->last_visited( $self->timestamp );
}

#----------------------------------------------------------------------#

sub update_cdp_neighbors {
    my $self = shift;

    my $source = $self->source;
    my $entry  = $self->entry;
    my $schema = $self->schema;

    my $neighbors = $source->neighbors;
    while ( my ( $p, $n ) = each(%$neighbors) ) {
        foreach my $s (@$n) {
            my $link = $self->schema->resultset('CDPNeigh')->update_or_create(
                {
                    from_device    => $entry->id,
                    from_interface => $p,
                    to_device      => $s->{addr},
                    to_interface   => $s->{port},
                    last_seen      => $self->Timestamp
                }
            );
            $link->update;
        }
    }

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

    my $uplinks = $self->uplinks;
    $self->log->debug( "device uplinks: ", join( ",", keys %$uplinks ) );

    my $timestamp = $self->timestamp;
    my $device_id = $entry->id;

    my $ignore_portchannel = $self->config->{ignore_portchannel};

    my $mat = $source->mat();
    while ( my ( $vlan, $entries ) = each(%$mat) ) {
        $self->log->debug("updating mat vlan $vlan");

        ( $vlan eq 'default' ) and $vlan = $self->native_vlan;

        while ( my ( $m, $p ) = each %$entries ) {
            next if $uplinks->{$p};

            next if $ignore_portchannel && lc($p) =~ /^port-channel/;

            my @mat_entries = $self->schema->resultset('Mat')->search(
                {
                    macaddr   => $m,
                    device    => $device_id,
                    interface => $p,
                    archived  => 0,
                }
            );
            if ( scalar(@mat_entries) > 1 ) {
                $self->log->error( "More than one non archived entry for ",
                    $entry->name, ",$m,$p" );
                next;
            }
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

    # TODO
}

#----------------------------------------------------------------------#

sub update_vtp_database {
    my $self = shift;

    my $source = $self->source;
    my $entry  = $self->entry;

    my $vlan_db = $source->vtp_database;

    $self->log->info( "getting vtp info from", $entry->id );
    if ( !defined($vlan_db) ) {
        $self->log->error("cannot retrieve vtp info");
        return;
    }

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
}

sub update_arp_table {
    my $self = shift;

    my $source = $self->source;
    my $entry  = $self->entry;

    my $vlan = $entry->vlan_arpinfo() || $self->config->{default_vlan};

}

#----------------------------------------------------------------------#

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
