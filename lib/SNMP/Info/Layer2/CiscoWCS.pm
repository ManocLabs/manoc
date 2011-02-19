
package SNMP::Info::Layer2::CiscoWCS;
$VERSION = '1.00';

use strict;

use Exporter;
use SNMP::Info::Layer2;
use SNMP::Info::Entity;
use SNMP::Info::EtherLike;
use SNMP::Info::CiscoStats;
use SNMP::Info::CiscoVTP;
use SNMP::Info::CDP;

@SNMP::Info::Layer2::Aironet1240::ISA = qw(
    SNMP::Info::Layer2
    SNMP::Info::Entity
    SNMP::Info::EtherLike
    SNMP::Info::CiscoStats
    SNMP::Info::CiscoVTP
    SNMP::Info::CDP
    Exporter
);

@SNMP::Info::Layer2::Aironet1240::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD $INIT $DEBUG/;

%MIBS = (
    'CISCO-LWAPP-DOT11-CLIENT-MIB' =>

);

%GLOBALS = (
    %SNMP::Info::Layer2::GLOBALS,    %SNMP::Info::Entity::GLOBALS,
    %SNMP::Info::EtherLike::GLOBALS, %SNMP::Info::CiscoStats::GLOBALS,
    %SNMP::Info::CiscoVTP::GLOBALS,  %SNMP::Info::CDP::GLOBALS,
);

%FUNCS = (
    %SNMP::Info::Layer2::FUNCS,
    %SNMP::Info::Entity::FUNCS,
    %SNMP::Info::EtherLike::FUNCS,
    %SNMP::Info::CiscoStats::FUNCS,
    %SNMP::Info::CiscoVTP::FUNCS,
    %SNMP::Info::CDP::FUNCS,

    cldc_client_mac      => 'cldcClientMacAddress',
    cldc_client_status   => 'cldcClientStatus',
    cldc_client_wprofile => 'cldcClientWlanProfileName',
    cldc_client_protocol => 'cldcClientProtocol',
    cldc_assoc_mode      => 'cldcAssociationMode',
    cldc_ap_address      => 'cldcApMacAddress',

);

%MIBS = (
    %SNMP::Info::Layer2::MIBS,    %SNMP::Info::Entity::MIBS,
    %SNMP::Info::EtherLike::MIBS, %SNMP::Info::CiscoStats::MIBS,
    %SNMP::Info::CiscoVTP::MIBS,  %SNMP::Info::CDP::MIBS,
);

%MUNGE = (
    %SNMP::Info::Layer2::MUNGE,
    %SNMP::Info::Entity::MUNGE,
    %SNMP::Info::EtherLike::MUNGE,
    %SNMP::Info::CiscoStats::MUNGE,
    %SNMP::Info::CiscoVTP::MUNGE,
    %SNMP::Info::CDP::MUNGE,

    cldc_client_mac => \&SNMP::Info::munge_mac,
    cldc_assoc_mode => 'cldcAssociationMode',
    cldc_ap_address => \&SNMP::Info::munge_mac,
);

sub vendor {
    return 'cisco';
}

sub interfaces {
    my $aironet       = shift;
    my $i_description = $aironet->i_description();

    return $i_description;
}

# Tag on e_descr.1
sub description {
    my $aironet = shift;
    my $descr   = $aironet->descr();
    my $e_descr = $aironet->e_descr();

    $descr = "$e_descr->{1}  $descr" if defined $e_descr->{1};

    return $descr;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::Aironet1240 - SNMP Interface to Cisco Aironet 1240.

=head1 AUTHOR

Gabriele Mambrini

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $aironet = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $aironet->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

xNote there are other two classes for Aironet devices :

=over

=item SNMP::Info::Layer3::Aironet

This class is for devices running Aironet software (older)

=item SNMP::Info::Layer2::Aironet

This class is for devices running Cisco IOS software (newer)

=back

For speed or debugging purposes you can call the subclass directly,
but not after determining a more specific class using the method
above.

my $aironet = new SNMP::Info::Layer2::Aironet1240(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=item SNMP::Info::Entity

=item SNMP::Info::EtherLike

=item SNMP::Info::CiscoVTP

=item SNMP::Info::CiscoDot11

=back

=head2 Required MIBs

=over

=item Inherited Classes

MIBs required by the inherited classes listed above.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $aironet->discription()

Adds info from method e_descr() from SNMP::Info::Entity

=item $aironet->vendor()

    Returns 'cisco' :)

=back

=head2 Globals imported from SNMP::Info::Layer2

See documentation in SNMP::Info::Layer2 for details.

=head2 Globals imported from SNMP::Info::Entity

See documentation in SNMP::Info::Entity for details.

=head2 Globals imported from SNMP::Info::EtherLike

See documentation in SNMP::Info::EtherLike for details.

=head1 TABLE ENTRIES

=head2 Overrides

=over

=item $aironet->interfaces()

Uses the i_description() field.

=item $aironet->i_duplex()

Crosses information from SNMP::Info::EtherLike to get duplex info for interfaces.

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See documentation in SNMP::Info::Layer2 for details.

=head2 Table Methods imported from SNMP::Info::Entity

See documentation in SNMP::Info::Entity for details.

=head2 Table Methods imported from SNMP::Info::EtherLike

See documentation in SNMP::Info::EtherLike for details.

=head2 Table Methods imported from SNMP::Info::CiscoDot11

See documentation in SNMP::Info::CiscoDot11 for details.


=head1 AUTHOR

See README

=head1 LICENSE

Copyright 2011 by the Manoc Team

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
