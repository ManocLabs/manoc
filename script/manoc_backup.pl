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
use Manoc::IpAddress;

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

has ['count_uptodate', 'count_updated', 'count_error', 'count_new'] => (
    is         => 'rw',
    isa        => 'Int',
    default    => 0,
);
        

sub _build_timestamp { time }

sub visit_all { 
    my $self = shift;
    my ( $res, $message );
    #Get devices from DB
    my @device_ids = $self->schema->resultset('Device')->get_column('id')->all;
    @device_ids    = map Manoc::Utils::unpadded_ipaddr($_), @device_ids;
    
    my %visited = map { $_ => 0 } @device_ids;
    #Visit all devices
    foreach my $host (@device_ids) {
        ( $res, $message ) = $self->do_device( $host, \%visited );
        if ( !$res ) {
            $self->log->error("configuration for $host not saved: $message");
            $self->count_error( $self->count_error + 1 );
        }
        else {
            $self->log->debug("$host done");
        }
    }
    
    
}

sub visit_device {
    my ( $self, $host, $visited_ref ) = @_;
    my ( $res, $message );
    ( $res, $message ) = $self->do_device( $host,$visited_ref );

    if ( !$res ) {
        $self->log->error("configuration for $host not saved: $message");
        $self->error_count( $self->error_count + 1);
    } else {
        $self->log->debug("$host done");
   
    }
}

sub do_device {
    my ( $self, $device_id, $visited_ref ) = @_;
    my ( $config, $message, $res );

    my $device = $self->schema->resultset('Device')->find($device_id);
    $device or return ( 0, "$device_id not in device list" );

    if ( $device->backup_enabled == 1 ) {

        # TODO
        die "Not implemented yet";
        #Get configuration 
        #( $config, $message ) =
        #  Manoc::CiscoUtils->get_config( $device_ipobj, $self->schema,
        #    $self->config->{'Credentials'} );
        #$config or return ( 0, $message );

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
        $visited_ref->{$device_id} = 1;
        return ( 1, "Backup disabled" );
    }
}

sub compare {
    my ($prev_config, $config, $ignore) = @_;
    my @ignore;

    if(defined($ignore)){
        if ( ref($ignore) eq 'ARRAY' ) {
            @ignore = @$ignore;
        }
        else {
            push @ignore, $ignore;
        }
        foreach my $statement (@ignore){
            $prev_config =~ s/^$statement.*$//mg;
            $config      =~ s/^$statement.*$//mg;
        }
    }

    return ($prev_config eq $config);
}

sub update_device_config {
    my ( $self, $device_id, $config ) = @_;
    my $dev_config;

    my $ip_obj = Manoc::IpAddress->new( $device_id );

    #Get device configuration from DB
    $dev_config =
      $self->schema->resultset('DeviceConfig')
      ->find( { device => $ip_obj } );

    #Update entry
    if ($dev_config) {

        my $ignore_statements = $self->config->{'Backup'}->{'ignore'};

        #Already up to date
        if ( compare($config,$dev_config->config,$ignore_statements) ) {

            $dev_config->last_visited( $self->timestamp );
            $dev_config->update or return ( 0, "Impossible update DB" );
            $self->log->info("$device_id backup is up to date");
            $self->count_uptodate( $self->count_uptodate + 1);
        } else {
            #Update configuration
            $dev_config->prev_config( $dev_config->config );
            $dev_config->prev_config_date( $dev_config->config_date );
            $dev_config->config($config);
            $dev_config->config_date( $self->timestamp );
            $dev_config->last_visited( $self->timestamp );
            $dev_config->update or return ( 0, "Impossible update DB" );
            $self->log->info("$device_id backup updated");
            $self->count_updated($self->count_updated + 1);

        }

    } else {
        #Create DB entry
        $self->schema->resultset('DeviceConfig')->create(
            {
                device       => $ip_obj,
                config       => $config,
                config_date  => $self->timestamp,
                last_visited => $self->timestamp
            }
        ) or return ( 0, "Impossible update DB" );
        $self->log->info("$device_id backup created");
        $self->count_new($self->count_new + 1);
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
    $self->device ? $self->visit_device( $self->device, {$self->device => 0} ) : $self->visit_all();
    
    #Print final report
    $self->log->info("Backup Done");
    $self->log->info("Configurations up to date:  " . $self->count_uptodate );
    $self->log->info("Configurations updated:     " . $self->count_updated );
    $self->log->info("New configurations created: " . $self->count_new );
    $self->log->info("Errors occurred:            " . $self->count_error );

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
