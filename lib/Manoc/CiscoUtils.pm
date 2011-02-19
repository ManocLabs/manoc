package Manoc::CiscoUtils;

# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

use Net::Telnet::Cisco;
use Regexp::Common qw /net/;
use Config::Simple;
use Carp;
use strict;
use warnings;

my $Conf;

sub get_pwds {
    my ( $device_id, $schema, $conf ) = @_;
    my ( $device, $telnet_pwd, $enable_pwd );

    #Retrieve device passwords from DB
    $device = $schema->resultset('Device')->find( { id => $device_id } );
    $device or return ( undef, undef );
    $telnet_pwd = $device->telnet_pwd;
    $enable_pwd = $device->enable_pwd;

    #Read parameters from config file (if needed)
    if ( !$telnet_pwd || !$enable_pwd ) {
        $telnet_pwd = $conf->{'telnet'} or return ( undef, undef );
        $enable_pwd = $conf->{'enable'} or return ( undef, undef );
    }

    return ( $telnet_pwd, $enable_pwd );
}

sub login_device {
    my ( $device_id, $telnet_pwd, $enable_pwd ) = @_;
    my $session;

    #Connect and login in enable mode
    eval {
        $session = Net::Telnet::Cisco->new(
            Host    => $device_id,
            Timeout => 20,
        );
        $session->login( 'admin', $telnet_pwd ) or return (undef);
        $enable_pwd and
            $session->enable($enable_pwd) or
            return (undef);
    };
    $@ and return (undef);

    return $session;
}

sub switch_port_status {
    my ( $self, $device_id, $iface_id, $schema ) = @_;
    my ( $interface, $status, $telnet_pwd, $enable_pwd, $session );

    #Retrieve interface from DB
    $interface = $schema->resultset('IfStatus')->find(
        {
            device    => $device_id,
            interface => $iface_id
        }
    );
    $interface or return ( 0, "Cannot find interface in DB" );
    $status = $interface->up_admin;

    #Get passwords to login
    ( $telnet_pwd, $enable_pwd ) = get_pwds( $device_id, $schema );
    ( $telnet_pwd and $enable_pwd ) or
        return ( 0, "Impossible retrieve device passwords to login" );

    #Check host ip (and untaint data)
    if ( $device_id =~ /(^$RE{net}{IPv4}$)/ ) {
        $device_id = $1;
    }
    else {
        return ( 0, "Invalid host" );
    }

    #Connect to host and invert interface status
    $session = login_device( $device_id, $telnet_pwd, $enable_pwd );
    $session or return ( 0, "Impossible login to device" );
    eval {
        $session->cmd("configure terminal") or
            return ( 0, "Impossible configure interface $iface_id" );
        $session->cmd("interface $iface_id") or return ( 0, "Invalid interface: $iface_id" );
        if ( $status eq "up" ) {
            $session->cmd("shutdown") or
                return ( 0, "Impossible configure interface $iface_id" );
        }
        else {
            $session->cmd("no shutdown") or
                return ( 0, "Impossible configure interface $iface_id" );
        }
    };
    $@ and return ( 0, "Impossible configure interface $iface_id" );

    $session->close();
}

sub get_config {
    my ( $self, $device_id, $schema, $appconf ) = @_;
    my ( $telnet_pwd, $enable_pwd, $session, @config_arr, $config );

    #Get passwords to login
    ( $telnet_pwd, $enable_pwd ) = get_pwds( $device_id, $schema, $appconf );
    ( $telnet_pwd && $enable_pwd ) or
        return ( undef, "Impossible retrieve device passwords to login" );

    #Login in enable mode
    $session = login_device( $device_id, $telnet_pwd, $enable_pwd );
    $session or return ( undef, "Impossible login to device" );

    #Get device configuration
    eval { @config_arr = $session->cmd("show running"); };
    $@ and return ( undef, "Impossible get device configuration" );

    $session->close();

    #Convert config array to string
    foreach (@config_arr) {
        $config .= $_;
    }

    return ( $config, "Ok" );
}

sub save_config {
    my ( $self, $device_id, $schema ) = @_;

    #Get passwords to login
    my ( $telnet_pwd, $enable_pwd ) = get_pwds( $device_id, $schema );
    ( $telnet_pwd && $enable_pwd ) or
        return ( undef, "Impossible retrieve device passwords to login" );

    #Login in enable mode
    my $session = login_device( $device_id, $telnet_pwd, $enable_pwd );
    $session or return ( undef, "Impossible login to device" );

    my $r = $session->cmd("copy running-config startup-config") or
        return ( 0, "Cannot save configuration" );
    return ( 1, $r );
}

1;

