# SNMP::Info::CiscoDot11

# Copyright (c) 2007, Gabriele Mambrini
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

package SNMP::Info::CiscoDot11;

use strict;

use Exporter;
use SNMP::Info;

use vars qw/$VERSION $DEBUG %MIBS %FUNCS %GLOBALS %MUNGE $INIT/;
@SNMP::Info::CiscoDot11::ISA       = qw/SNMP::Info Exporter/;
@SNMP::Info::CiscoDot11::EXPORT_OK = qw//;

%MIBS = (
    'CISCO-DOT11-ASSOCIATION-MIB' => 'cDot11ParentAddress',
    'CISCO-DOT11-IF-MIB'          => 'cd11IfAuxSsid',
);

%GLOBALS = (
    'cd11_parent' => 'cDot11ParentAddress.0',
    'serial'      => 'entPhysicalSerialNum.1',
    'descr'       => 'sysDescr'
);

%FUNCS = (
    'cd11_client_parent'      => 'cDot11ClientParentAddress',
    'cd11_client_wep'         => 'cDot11ClientWepEnabled',
    'cd11_client_mic'         => 'cDot11ClientMicEnabled',
    'cd11_client_datarate'    => 'cDot11ClientDataRateSet',
    'cd11_client_vlan'        => 'cDot11ClientVlanId',
    'cd11_client_ipaddress'   => 'cDot11ClientIpAddress',
    'cd11_client_sigstrength' => 'cDot11ClientSignalStrength',
    'cd11_client_sigquality'  => 'cDot11ClientSigQuality',
    'cd11_client_state'       => 'cDot11ClientAssociationState',
    'cd11_client_authen'      => 'cDot11ClientAuthenAlgorithm',
    'cd11_client_addauthen'   => 'cDot11ClientAdditionalAuthen',
    'cd11_client_1xauthen'    => 'cDot11ClientDot1xAuthenAlgorithm',
    'cd11_client_keymgt'      => 'cDot11ClientKeyManagement',
    'cd11_client_ucipher'     => 'cDot11ClientUnicastCipher',
    'cd11_client_mcipher'     => 'cDot11ClientMulticastCipher',

    'cd11_cip_micfail'   => 'cd11IfCipherMicFailClientAddress',
    'cd11_cip_tkiplfail' => 'cd11IfCipherTkipLocalMicFailures',
    'cd11_cip_tkiprfail' => 'cd11IfCipherTkipRemotMicFailures',

    'i_ssidlist' => 'cd11IfAuxSsid',

    'i_ssidbcast'    => 'cd11IfAuxSsidBroadcastSsid',
    'i_80211channel' => 'cd11IfPhyDsssCurrentChannel',
);

%MUNGE = (
    'cd11_parent'           => \&SNMP::Info::munge_mac,
    'cd11_client_parent'    => \&SNMP::Info::munge_mac,
    'cd11_client_ipaddress' => \&SNMP::Info::munge_ip,
    'cd11_client_ucipher'   => \&munge_dot11_cipher,
    'cd11_client_mcipher'   => \&munge_dot11_cipher,
    'cd11_client_addauthen' => \&munge_dot11_addauthen,
    'cd11_client_1xauthen'  => \&munge_dot11_1xauthen,
    'cd11_client_keymgt'    => \&munge_dot11_keymgt
);

sub has_cd11 {
    return 1;
}

sub cd11_client_index {
    my $self = shift;

    my %index;
    my $client_parent = $self->cd11_client_parent;

    while ( my ( $k, $v ) = each(%$client_parent) ) {
        my @nodes    = split /\./, $k;
        my $if_index = shift @nodes;
        my $ssid_len = shift @nodes;
        my $ssid     = pack( 'C*', splice( @nodes, 0, $ssid_len ) );
        my $addr     = join( ':', map { sprintf "%02x", $_ } @nodes );

        $index{$k} = {
            if_index => $if_index,
            ssid     => $ssid,
            address  => $addr,
        };
    }

    return \%index;
}

sub munge_dot11_cipher {
    my $bits = shift;
    return {
        ckip   => vec( $bits, 7, 1 ),
        cmic   => vec( $bits, 6, 1 ),
        tkip   => vec( $bits, 5, 1 ),
        wep40  => vec( $bits, 4, 1 ),
        wep128 => vec( $bits, 3, 1 ),
        aesccm => vec( $bits, 2, 1 )
    };
}

sub munge_dot11_keymgt {
    my $bits = shift;
    return {
        wpa  => vec( $bits, 7, 1 ),
        cckm => vec( $bits, 6, 1 ),
    };
}

sub munge_dot11_addauthen {
    my $bits = shift;
    return {
        mac => vec( $bits, 7, 1 ),
        eap => vec( $bits, 6, 1 ),
    };
}

sub munge_dot11_1xauthen {
    my $bits = shift;
    return {
        md5     => vec( $bits, 7, 1 ),
        leap    => vec( $bits, 6, 1 ),
        peap    => vec( $bits, 5, 1 ),
        eapTls  => vec( $bits, 4, 1 ),
        eapSim  => vec( $bits, 3, 1 ),
        eapFast => vec( $bits, 2, 1 ),
    };
}
1;

__END__

=head1 NAME

SNMP::Info::CiscoDot11 - Perl Interface to Cisco 802.11 MIBs using SNMP

=head1 AUTHOR

Gabriele Mambrini

=head1 SYNOPSYS

 my $info =  new SNMP::Info ( 
                             AutoSpecify => 1,
                             Debug       => 1,
                             DestHost    => 'switch', 
                             Community   => 'public',
                             Version     => 2
                           );

 my $class = $cdp->class();
 print " Using device sub class : $class\n";

 $hascdot11   = $cdp->has_cd11() ? 'yes' : 'no';

 # SSID infos
 my $interfaces	= $info->interfaces; 
 my $ssidlist	= $info->i_ssidlist;
 my $ssidbcast	= $info->i_ssidbcast;
 my $channel 	= $info->i_80211channel;    

 while (my ($k, $v) = each(%$ssidlist)) {
   my $iid = $k; 
   $iid =~ s/\.\d+//o;
   
   my $port      = $interfaces->{$iid},
   my $ssid      = $ssidlist->{$k},
   my $broadcast = $ssidbcast->{$k},
   my $channel	 = $channel->{$iid},
 }

 # (some) association infos

 my $client_index  	= $info->cd11_client_index;
 my $client_state  	= $info->cd11_client_state;x
 my $client_ip     	= $info->cd11_client_ipaddress;
 my $client_wep    	= $info->cd11_client_wep;
 my $client_vlan   	= $info->cd11_client_vlan;
 my $client_sigq   	= $info->cd11_client_sigquality;
 my $client_sigstr 	= $info->cd11_client_sigstrength;

 while (my ($k, $v) = each(%$client_index)) {
   my $port    = $interfaces->{$v->{if_index}};
   my $ssid    = $v->{ssid};
   my $macaddr = $v->{address};

   my $state   = $client_state->{$k};
   my $ipaddr  = $client_ip->{$k};
   my $vlan    = $client_vlan->{$k};
   my $wep     = $client_wep->{$k};

   my $quality =  $client_sigq->{$k};
   my $power   =  $client_sigstr->{$k};
}

Create or use a device subclass that inherits this class.  Do not use directly.

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item CISCO-DOT11-ASSOCIATION-MIB

=item  CISCO-CDP-MIB

=back

MIBs can be found at ftp://ftp.cisco.com/pub/mibs/v2/v2.tar.gz

=head1 TABLE METHODS

=head2 Dot11Client

=over

=item cd11_client_index

Returns the mapping to the SNMP2 Interface table fot Dot11Client.

The table is index using interface index, SSID and client mac address, these infos are also provided as an hash reference in the values of this hash.

 my $client_index  	= $info->cd11_client_index;
 while (my ($k, $v) = each(%client_index)) {
   my $iif     = $v->{if_index};
   my $ssid    = $v->{ssid};
   my $macaddr = $v->{address}
 }

=item cd11_client_parent

(B<cDot11ClientParentAddress>)

=item cd11_client_wep

(B<cDot11ClientWepEnabled>)

=item cd11_client_mic

(B<cDot11ClientMicEnabled>)

=item cd11_client_datarate

(B<cDot11ClientDataRateSet>)

=item cd11_client_vlan

(B<cDot11ClientVlanId>)

=item cd11_client_ipaddress

(B<cDot11ClientIpAddress>)

=item cd11_client_sigstrength

(B<cDot11ClientSignalStrength>)

=item cd11_client_sigquality

(B<cDot11ClientSigQuality>)

=item cd11_client_state

(B<cDot11ClientAssociationState>)

=item cd11_client_authen

(B<cDot11ClientAuthenAlgorithm>)


=item cd11_client_addauthen

(B<cDot11ClientAdditionalAuthen>)

=item cd11_client_1xauthen

(B<cDot11ClientDot1xAuthenAlgorithm>)

=item cd11_client_keymgt

(B<cDot11ClientKeyManagement>)

=item cd11_client_ucipher

(B<cDot11ClientUnicastCipher>)

=item cd11_client_mcipher

(B<cDot11ClientMulticastCipher>)

=cut
