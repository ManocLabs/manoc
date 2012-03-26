# SNMP::Info::Layer2::C2960

# Copyright (c) 2012, Enrico Liguori
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL <copyright holder> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package SNMP::Info::Layer2::C2960;

use strict;
use Exporter;
use SNMP::Info::CiscoVTP;
use SNMP::Info::CDP;
use SNMP::Info::CiscoStats;
use SNMP::Info::CiscoImage;
use SNMP::Info::CiscoRTT;
use SNMP::Info::CiscoQOS;
use SNMP::Info::CiscoConfig;
use SNMP::Info::CiscoPower;
use SNMP::Info::Layer3;

@SNMP::Info::Layer2::C2960::ISA = qw/SNMP::Info::CiscoVTP SNMP::Info::CDP
    SNMP::Info::CiscoStats SNMP::Info::CiscoImage
    SNMP::Info::CiscoRTT  SNMP::Info::CiscoQOS
    SNMP::Info::CiscoConfig SNMP::Info::CiscoPower
    SNMP::Info::Layer3
    Exporter/;
@SNMP::Info::Layer2::C2960::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD $INIT $DEBUG/;

$VERSION = '1.0';

%MIBS = (
    %SNMP::Info::Layer3::MIBS,
    %SNMP::Info::CiscoPower::MIBS,
    %SNMP::Info::CiscoConfig::MIBS,
    %SNMP::Info::CiscoQOS::MIBS,
    %SNMP::Info::CiscoRTT::MIBS,
    %SNMP::Info::CiscoImage::MIBS,
    %SNMP::Info::CiscoStats::MIBS,
    %SNMP::Info::CDP::MIBS,
    %SNMP::Info::CiscoVTP::MIBS,
);

%GLOBALS = (
    %SNMP::Info::Layer3::GLOBALS,      %SNMP::Info::CiscoPower::GLOBALS,
    %SNMP::Info::CiscoConfig::GLOBALS, %SNMP::Info::CiscoQOS::GLOBALS,
    %SNMP::Info::CiscoRTT::GLOBALS,    %SNMP::Info::CiscoImage::GLOBALS,
    %SNMP::Info::CiscoStats::GLOBALS,  %SNMP::Info::CDP::GLOBALS,
    %SNMP::Info::CiscoVTP::GLOBALS, 
);

%FUNCS = (
    %SNMP::Info::Layer3::FUNCS,
    %SNMP::Info::CiscoPower::FUNCS,
    %SNMP::Info::CiscoConfig::FUNCS,
    %SNMP::Info::CiscoQOS::FUNCS,
    %SNMP::Info::CiscoRTT::FUNCS,
    %SNMP::Info::CiscoImage::FUNCS,
    %SNMP::Info::CiscoStats::FUNCS,
    %SNMP::Info::CDP::FUNCS,
    %SNMP::Info::CiscoVTP::FUNCS,
);

%MUNGE = (
    %SNMP::Info::Layer3::MUNGE,
    %SNMP::Info::CiscoPower::MUNGE,
    %SNMP::Info::CiscoConfig::MUNGE,
    %SNMP::Info::CiscoQOS::MUNGE,
    %SNMP::Info::CiscoRTT::MUNGE,
    %SNMP::Info::CiscoImage::MUNGE,
    %SNMP::Info::CiscoStats::MUNGE,
    %SNMP::Info::CDP::MUNGE,
    %SNMP::Info::CiscoVTP::MUNGE,
);


sub cisco_comm_indexing {
  return 1;
}

sub i_vlan {
  return $_[0]->i_vlan2;
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::C2960 - SNMP Interface to Cisco 2960 Series.

=head1 AUTHOR

Enrico Liguori

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $cisco = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $cisco->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION



=over

=item SNMP::Info::Layer2::C2960

This class is for devices running Cisco IOS software (version 15.0 too)

=back

For speed or debugging purposes you can call the subclass directly,
but not after determining a more specific class using the method
above.

my $cisco = new SNMP::Info::Layer2::C2960(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer3

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

=item $cisco->discription()

Adds info from method e_descr() from SNMP::Info::Entity

=item $cisco->vendor()

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

=item $cisco->interfaces()

Uses the i_description() field.

=item $cisco->i_duplex()

Crosses information from SNMP::Info::EtherLike to get duplex info for interfaces.

=back

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in SNMP::Info::Layer3 for details.

=head2 Table Methods imported from SNMP::Info::Entity

See documentation in SNMP::Info::Entity for details.

=head2 Table Methods imported from SNMP::Info::EtherLike

See documentation in SNMP::Info::EtherLike for details.

=head2 Table Methods imported from SNMP::Info::CiscoVTP

See documentation in SNMP::Info::CiscoVTP for details.

=head1 AUTHOR

See README

=head1 LICENSE

Copyright 2012 by the Manoc Team

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
