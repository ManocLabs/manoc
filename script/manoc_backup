#!/usr/bin/perl
# -*- cperl -*-
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Manoc::Support;

package Manoc::Backup;
use Moose;
use Manoc::Logger;
use Manoc::Utils qw(str2seconds print_timestamp);
use Manoc::CiscoUtils;
use Manoc::Report::BackupReport;

use Sys::Hostname qw(hostname);
 
extends 'Manoc::App';

has 'device' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has 'timestamp' => (
    traits     => ['NoGetopt'],
    is         => 'ro',
    isa        => 'Int',
    required   => 0,
    lazy_build => 1,
);

has 'report' => (
    traits   => ['NoGetopt'],
    is       => 'rw',
    isa      => 'Manoc::Report::BackupReport',
    required => 0,
    default  => sub { Manoc::Report::BackupReport->new },
);

sub _build_timestamp { time }

sub visit_all {
    my $self = shift;
    my ( $res, $message );

    #Get devices from DB
    my @device_ids = $self->schema->resultset('Device')->get_column('id')->all;
    my %visited = map { $_ => 0 } @device_ids;

    #Visit all devices
    foreach my $host (@device_ids) {
        ( $res, $message ) = $self->do_device( $host, \%visited );
        if ( !$res ) {
            $self->log->error("configuration for $host not saved: $message");
            $self->report->add_error( {id => $host, message => $message } );
        }
        else {
            $self->log->debug("$host done");
        }
    }
}

sub visit_device {
    my ( $self, $host ) = @_;
    my ( $res, $message );
    ( $res, $message ) = $self->do_device( $host, { $host => 0 } );

    if ( !$res ) {
        $self->log->error("configuration for $host not saved: $message");
        $self->report->add_error( {id => $host, message => $message } );
    }
    else {
        $self->log->debug("$host done");
    }
}

sub do_device {
    my ( $self, $device_id, $visited_ref ) = @_;
    my ( $config, $message, $res );

    #Check device id
    my $device = $self->schema->resultset('Device')->find($device_id);
    $device or return ( 0, "$device_id not in device list" );

    if ( $device->backup_enabled == 1 ) {

        #Get configuration via telnet
        ( $config, $message ) =
          Manoc::CiscoUtils->get_config( $device_id, $self->schema,
            $self->config->{'Backup'} );
        $config or return ( 0, $message );

        #Update configuration in DB
        ( $res, $message ) = $self->update_device_config( $device_id, $config );
        $res or return ( 0, $message );

        #Update "visited" structure
        $visited_ref->{$device_id} = 1;

        return ( 1, "Ok" );

    }
    else {

        #Backup disabled
        my $message = "device $device_id has backup disabled";
        $self->log->info($message);
        $self->report->add_error( {id => $device, message => $message } );

        return ( 1, "Backup disabled" );

    }
}

sub update_device_config {
    my ( $self, $device_id, $config ) = @_;
    my $dev_config;

    #Get device configuration from DB
    $dev_config =
      $self->schema->resultset('DeviceConfig')
      ->find( { device => $device_id } );

    #Update entry
    if ($dev_config) {

        #Already up to date
        if ( $config eq $dev_config->config ) {

            $dev_config->last_visited( $self->timestamp );
            $dev_config->update or return ( 0, "Impossible update DB" );
            $self->log->info("$device_id backup is up to date");
            $self->report->add_up_to_date( $device_id );

            #Update configuration
        }
        else {

            $dev_config->prev_config( $dev_config->config );
            $dev_config->prev_config_date( $dev_config->config_date );
            $dev_config->config($config);
            $dev_config->config_date( $self->timestamp );
            $dev_config->last_visited( $self->timestamp );
            $dev_config->update or return ( 0, "Impossible update DB" );
            $self->log->info("$device_id backup updated");
            $self->report->add_updated( $device_id );

        }

    }
    else {

        #Create DB entry

        $self->schema->resultset('DeviceConfig')->create(
            {
                device       => $device_id,
                config       => $config,
                config_date  => $self->timestamp,
                last_visited => $self->timestamp
            }
        ) or return ( 0, "Impossible update DB" );
        $self->log->info("$device_id backup created");
        $self->report->add_created( $device_id );

    }

    return ( 1, "Ok" );
}

########################################################################

sub check_lastrun {
    my $self     = shift;
    my $interval = Manoc::Utils::str2seconds(
        $self->config->{'Backup'}->{'interval'} );

    $interval or $self->log->logdie("Backup interval not configured");

    my $last_run_entry =
      $self->schema->resultset('System')->find("backup.lastrun");
    my $last_run_date = $last_run_entry ? $last_run_entry->value : 0;

    return ( $self->timestamp - $last_run_date > $interval );
}

sub update_lastrun {
    my ($self) = @_;
    $self->schema->resultset('System')->update_or_create(
        name  => "backup.lastrun",
        value => $self->timestamp,
    );
}

########################################################################

sub run {
    my ($self) = @_;
    my $timestamp = time();

    $self->check_lastrun or $self->log->logdie("Too soon to backup again!");

    #Start backup
    $self->device ? $self->visit_device( $self->device ) : $self->visit_all();

    #Print final report
    $self->log->info("Backup Done");
    $self->log->info(
        "Configurations up to date:  " . $self->report->up_to_date_count );
    $self->log->info( "Configurations updated:     " . $self->report->updated_count );
    $self->log->info(
        "Configurations not saved:   " . $self->report->not_updated_count );
    $self->log->info( "New configurations created: " . $self->report->created_count );
    $self->log->info( "Errors occurred:            " . $self->report->error_count );

    $self->schema->resultset('ReportArchive')->create(
        {
            timestamp => $timestamp,
	    name      => hostname,
	    type      => 'BackupReport',
            s_class   => $self->report,
        }
    );

    $self->update_lastrun;

    exit 0;
}

no Moose;

package main;

my $app = Manoc::Backup->new_with_options();
$app->run();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
