# Copyright 2011-2016 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

# A frontend for Net::SNMP

package Manoc::Manifold::SNMP::Simple;
use Moose;

with 'Manoc::ManifoldRole::Base',
    'Manoc::ManifoldRole::Host',
    'Manoc::ManifoldRole::Hypervisor',
    'Manoc::Logger::Role';

use Net::SNMP 6.0 qw( :snmp DEBUG_ALL ENDOFMIBVIEW );

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
    isa     => 'Str',
    lazy    => '1',
    builder => '_build_version',
);

has 'snmp_session' => (
    is     => 'ro',
    isa    => 'Object',
    writer => '_set_snmp_session',
);

sub _build_community {
    my $self = shift;

    return $self->credentials->{snmp_community} || 'public';
}

sub _build_version {
    my $self = shift;
    my $version = $self->credentials->{snmp_version} || 2;

    my %version_map = (
        '1'  => 'snmpv1',
        '2'  => 'snmpv2c',
        '2c' => 'snmpv2c',
        '3'  => 'snmpv3'
    );
    return $version_map{$version};
}

sub connect {
    my ($self) = @_;
    my $opts = shift || {};

    my $info;

    my %options;
    $options{-hostname} = $self->host;

    my $extra_params = $self->extra_params;
    $options{-version}   = $self->version;
    $options{-community} = $self->community;

    my @extra_options = qw(  -port -timeout -retries
        -localaddr -localport -username -authkey
        -authpassword -authprotocol
        -privkey -privpassword -privprotocol
    );
    foreach (@extra_options) {
        $options{$_} = $extra_params->{$_} if exists $extra_params->{$_};
    }

    # $options{-debug} = DEBUG_ALL
    #  if ( defined(_debug_level) && _debug_level > 1 );

    $options{-translate} = [
        '-all'            => 1,
        '-octetstring'    => 0,
        '-null'           => 1,
        '-timeticks'      => 0,
        '-opaque'         => 1,
        '-nosuchobject'   => 1,
        '-nosuchinstance' => 1,
        '-endofmibview'   => 1,
        '-unsigned'       => 1,
    ];

    my $session;
    try {
        $session = Net::SNMP->session(%options);
    }
    catch {
        my $msg = "Could not connect to " . $self->host . " .$_";
        $self->log->error($msg);
        return undef;
    };

    unless ($session) {
        $self->log->error( "Could not connect to ", $self->host );
        return undef;
    }

    $self->_set_snmp_session($session);
    return 1;
}

#----------------------------------------------------------------------#
#
#                 SNMP scalar and table declaration
#
#----------------------------------------------------------------------#

sub has_snmp_scalar {
    my ( $name, %options ) = @_;

    my $oid = $options{oid} or croak "oid attribute is required";
    my $munger = $options{munger};

    my $attr_name    = "snmp_$name";
    my $builder_name = "_build_${attr_name}";

    has $attr_name => (
        is      => 'ro',
        lazy    => 1,
        builder => "_build_${attr_name}"
    );

    {
        no strict 'refs';
        *{$builder_name} = sub {
            my $self = shift;
            $self->_mib_read_scalar( $oid, $munger );
            }
    }
}

=head 2 has_snmp_table

Creates a snmp_<columnname> accessor for each defined column.

=cut

sub has_snmp_table {
    my ( $name, %options ) = @_;
    my $table_oid = $options{oid};
    $table_oid or croak "Table $name has no oid";

    my $columns = $options{columns};
    $columns or croak "Table $name has no columns definition";

    my @column_names = keys %$columns;
    while ( my ( $col_name, $col_opts ) = each(%$columns) ) {
        ref $col_opts eq 'ARRAY' or $col_opts = [$col_opts];
        my ( $sub_id, $munger ) = @$col_opts;
        my $col_oid = "$table_oid.1.$sub_id";

        my $attr_name    = "snmp_$col_name";
        my $builder_name = "_build_${attr_name}";

        has $attr_name => (
            is      => 'ro',
            lazy    => 1,
            builder => $builder_name,
        );

        {
            no strict 'refs';
            *{$builder_name} = sub {
                my $self = shift;
                $self->_mib_read_tablerow( $col_oid, $munger );
                }
        }
    }
}

my $SNMPV2_MIB_OID = '1.3.6.1.2.1.1';
has_snmp_scalar "sysDescr"    => ( oid => "$SNMPV2_MIB_OID.1" );
has_snmp_scalar "sysObjectID" => ( oid => "$SNMPV2_MIB_OID.2" );
has_snmp_scalar "sysUpTime"   => ( oid => "$SNMPV2_MIB_OID.3" );
has_snmp_scalar "sysName"     => ( oid => "$SNMPV2_MIB_OID.5" );
has_snmp_scalar "sysLocation" => ( oid => "$SNMPV2_MIB_OID.6" );
has_snmp_scalar "sysServices" => ( oid => "$SNMPV2_MIB_OID.7" );

my $HOST_RESOURCES_MIB_OID = '1.3.6.1.2.1.25';
has_snmp_table 'hrSWInstalledTable' => (
    oid     => "$HOST_RESOURCES_MIB_OID.6.3",
    columns => {
        'hrSWInstalledIndex' => 1,
        'hrSWInstalledName'  => 2,
        'hrSWInstalledID'    => 3,
        'hrSWInstalledType'  => 4,
        'hrSWInstalledDate'  => [ 5, \&_munge_sw_installed_date ],
    },
);
has_snmp_table 'hrDeviceTable' => (
    oid     => "$HOST_RESOURCES_MIB_OID.3.2",
    index   => 'hrDeviceIndex',
    columns => {
        'hrDeviceType'   => 2,
        'hrDeviceDescr'  => 3,
        'hrDeviceID'     => 4,
        'hrDeviceStatus' => [
            5,
            sub {
                my $val   = shift;
                my @stati = qw(INVALID unknown running warning testing down);
                return $stati[$val];
            }
        ],
        'hrDeviceErrors' => 6,
    },
);

has_snmp_table 'hrProcessorTable' => (
    oid     => "$HOST_RESOURCES_MIB_OID.3.3",
    index   => 'hrDeviceIndex',
    columns => {
        'hrProcessorLoad' => 2,
    },
);

my $UCD_SNMP_MIB_OID = '.1.3.6.1.4.1.2021';
has_snmp_scalar 'memTotalReal' => ( oid => "${UCD_SNMP_MIB_OID}.4.5", );

my $VMWARE_SYSTEM_MIB = '.1.3.6.1.4.1.6876.1';
has_snmp_scalar 'vmwProdName'    => ( oid => "${VMWARE_SYSTEM_MIB}.1", );
has_snmp_scalar 'vmwProdVersion' => ( oid => "${VMWARE_SYSTEM_MIB}.1", );

my $VMWARE_VMINFO_MIB_OID = '.1.3.6.1.4.1.6876.2';
has_snmp_table 'vmwVmTable' => (
    oid     => "$VMWARE_VMINFO_MIB_OID.1",
    index   => "vmwVmIdx",
    columns => {
        vmwVmIdx         => 1,
        vmwVmDisplayName => 2,
        vmwVmGuestOS     => 4,
        vmwVmMemSize     => 5,
        vmwVmState       => 6,
        vmwVmCpus        => 9,
        vmwVmUUID        => 10
    },
);

#----------------------------------------------------------------------#

sub _build_boottime {
    my $self = shift;
    return time() - int( $self->snmp_sysUpTime / 100 );
}

sub _build_name {
    my $self = shift;
    return $self->snmp_sysName;
}

sub _build_model {
    my $self = shift;
    warn "TODO";
    return undef;
}

sub _build_os {
    my $self = shift;

    my $descr  = $self->snmp_sysDescr;
    my $vendor = $self->vendor;

    $vendor eq 'Microsoft' and $descr =~ /Software: Windows/ and return "Windows";

    if ( $vendor eq 'NetSNMP' ) {
        my @fields = split /\s+/, $descr;
        return $fields[0];
    }

    if ( $vendor eq 'Cisco' ) {
        return 'ios-xe'   if ( $descr =~ /IOS-XE/ );
        return 'ios-xr'   if ( $descr =~ /IOS XR/ );
        return 'ios'      if ( $descr =~ /IOS/ );
        return 'catalyst' if ( $descr =~ /catalyst/i );
        return 'css'      if ( $descr =~ /Content Switch SW/ );
        return 'css-sca'  if ( $descr =~ /Cisco Systems Inc CSS-SCA-/ );
        return 'pix'      if ( $descr =~ /Cisco PIX Security Appliance/ );
        return 'asa'      if ( $descr =~ /Cisco Adaptive Security Appliance/ );
        return 'san-os'   if ( $descr =~ /Cisco SAN-OS/ );
    }

    if ( $vendor eq 'VMWare' ) {
        my $prodname = $self->vmwProdName;
        return $prodname if defined($prodname);
    }

    return '';
}

sub _build_os_ver {
    my $self   = shift;
    my $descr  = $self->snmp_sysDescr;
    my $vendor = $self->vendor;

    $vendor eq 'Microsoft' and
        $descr =~ /Windows Version\s+([\d\.]+)/ and
        return $1;

    if ( $vendor eq 'NetSNMP' ) {
        my @fields = split /\s+/, $descr;
        return $fields[2];
    }

    if ( $vendor eq 'Cisco' ) {
        my $os = $self->os;

        if ( defined $os && defined $descr ) {
            # Older Catalysts
            if ( $os eq 'catalyst' && $descr =~ m/V(\d{1}\.\d{2}\.\d{2})/ ) {
                return $1;
            }

            if ( $os eq 'css' &&
                $descr =~ m/Content Switch SW Version ([0-9\.\(\)]+) with SNMPv1\/v2c Agent/ )
            {
                return $1;
            }

            if ( $os eq 'css-sca' &&
                $descr =~ m/Cisco Systems Inc CSS-SCA-2FE-K9, ([0-9\.\(\)]+) Release / )
            {
                return $1;
            }

            if ( $os eq 'pix' &&
                $descr =~ m/Cisco PIX Security Appliance Version ([0-9\.\(\)]+)/ )
            {
                return $1;
            }

            if ( $os eq 'asa' &&
                $descr =~ m/Cisco Adaptive Security Appliance Version ([0-9\.\(\)]+)/ )
            {
                return $1;
            }

            if ( $os =~ /^fwsm/ && $descr =~ m/Version (\d+\.\d+(\(\d+\)){0,1})/ ) {
                return $1;
            }

            if ( $os eq 'ios-xr' && $descr =~ m/Version (\d+[\.\d]+)/ ) {
                return $1;
            }

        }

        if ( $os =~ /^ace/ && $self->can('entPhysicalSoftwareRev') ) {
            my $ver = $self->entPhysicalSoftwareRev->{1};
            $ver and return $ver;
        }

        # Newer Catalysts and IOS devices
        if ( defined $descr and
            $descr =~ m/Version (\d+\.\d+\([^)]+\)[^,\s]*)(,|\s)+/ )
        {
            return $1;
        }
    }    # end of Cisco

    if ( $vendor eq 'VMWare' ) {
        my $prodver = $self->vmwProdVersion;
        return $prodver if defined($prodver);
    }

    return '';
}

sub _build_vendor {
    my $self = shift;
    my $info = $self->snmp_sysObjectID;
    return _sysObjectID2vendor($info) || "";
}

sub _build_serial {
    my $self = shift;
    return undef;
}

sub _build_cpu_count {
    my $self = shift;

    my $procLoad = $self->snmp_hrProcessorLoad;

    return scalar( keys(%$procLoad) );
}

sub _build_cpu_model { "Unkown" }

sub _build_ram_memory {
    my $self = shift;

    return int( $self->snmp_memTotalReal ) / 1024;
}

sub _build_kernel { undef }

sub _build_kernel_ver { undef }

has 'package_name_parser' => (
    is      => 'rw',
    isa     => 'Ref',
    lazy    => 1,
    builder => '_build_package_name_parser',
);

sub _build_package_name_parser {
    my $self = shift;

    my $os = $self->os;

    if ( $os eq 'Linux' ) {
        return sub {
            my $pkg = shift;

            # redhat name, version release platform
            $pkg =~ /^(.+)-([^-]+)-([^-]+)\.(.*)$/ and
                return [ $1,   $2 ];
            return     [ $pkg, undef ];
        };
    }

    return sub { [ shift, undef ] };
}

sub _build_installed_sw {
    my $self = shift;

    my $installed = $self->snmp_hrSWInstalledName;
    my $parser    = $self->package_name_parser;

    return [ map { $parser->($_) } values(%$installed) ];
}

sub _build_virtual_machines {
    my $self = shift;

    if ( $self->vendor eq 'VMWare' ) {
        my @result;

        $self->log->warn("Using vmware MIB to retrieve vm list ");

        my $names    = $self->snmp_vmwVmDisplayName;
        my $uuids    = $self->smmp_vmwVmUUID;
        my $memsizes = $self->snmp_vmwVmMemSize;
        my $vcpus    = $self->snmp_vmwVmCpus;

        while ( my ( $idx, $uuid ) = each(%$uuids) ) {
            my $vm_info = {};
            $vm_info->{uuid}    = $uuid;
            $vm_info->{name}    = $names->{$idx};
            $vm_info->{vcpus}   = $vcpus->{$idx};
            $vm_info->{memsize} = $memsizes->{$idx};

            push @result, $vm_info;
        }

        return \@result;
    }
}

#----------------------------------------------------------------------#
#
#                   SNMP gory details start here....
#
#----------------------------------------------------------------------#

# Implements get_scalar using Net::SNMP session

sub _get_scalar {
    my ( $self, $oid ) = @_;

    my $session = $self->snmp_session;

    #add istance number to the oid
    $oid .= '.0';

    $self->log->debug( $self->meta->name, "Fetching scalar $oid" );

    my $result = $session->get_request( '-varbindlist' => [$oid] );
    $result or die "SNMP error " . $session->error();

    return $result->{$oid};
}

# Implements get_subtree using Net::SNMP session

sub _get_subtree {
    my ( $self, $oid ) = @_;

    my @result;

    my $s = $self->snmp_session;
    $oid eq '.' and $oid = '0';

    $self->log->debug( $self->meta->name, "Fetching subtree $oid" );

    my $last_oid = $oid;

    if ( $s->version() == SNMP_VERSION_1 ) {

        while ( defined $s->get_next_request( -varbindlist => [$last_oid] ) ) {
            my $returned_oid = ( $s->var_bind_names() )[0];
            if ( !oid_base_match( $last_oid, $returned_oid ) ) {
                last;
            }

            # store into result
            push @result, [ $returned_oid, $s->var_bind_list()->{$returned_oid} ];

            $last_oid = $returned_oid;
        }

    }
    else {

    GET_BULK:
        while (
            defined $s->get_bulk_request(
                -maxrepetitions => 1,
                -varbindlist    => [$last_oid]
            )
            )
        {
            my @oids = $s->var_bind_names();

            if ( !scalar @oids ) {
                die('Received an empty varBindList');
            }

            foreach my $returned_oid (@oids) {

                if ( !oid_base_match( $oid, $returned_oid ) ) {
                    last GET_BULK;
                }

                # Make sure we have not hit the end of the MIB.
                if ( $s->var_bind_types()->{$returned_oid} == ENDOFMIBVIEW ) {
                    last GET_BULK;
                }

                push @result, [ $returned_oid, $s->var_bind_list()->{$returned_oid} ];

                $last_oid = $returned_oid;
            }
        }

    }

    return \@result;
}

sub _mib_read_scalar {
    my ( $self, $oid, $munger ) = @_;

    my $v = $self->_get_scalar($oid);
    $munger and $v = $munger->($v);
    return $v;
}

sub _mib_read_tablerow {
    my ( $self, $oid, $munger ) = @_;

    my $row = $self->_get_subtree($oid);

    my $ret = {};
    foreach (@$row) {

        # Don't optimize this RE!
        $_->[0] =~ /^$oid\.(.*)/ and $_->[0] = $1;
        $munger                  and $_->[1] = $munger->( $_->[1] );

        $ret->{ $_->[0] } = $_->[1];
    }

    return $ret;
}

# Takes a BOOLEAN and makes it a nop|true|false string

sub _munge_bool {
    my $bool = shift;
    my @ARR  = qw ( nop  false true);

    return $ARR[$bool];
}

# Takes a binary IP and makes it dotted ASCII

sub _munge_ipaddress {
    my $ip = shift;
    return join( '.', unpack( 'C4', $ip ) );
}

# Takes an octet stream (HEX-STRING) and returns a colon separated
# ASCII hex string.

sub _munge_macaddress {
    my $mac = shift;
    $mac or return "";
    $mac = join( ':', map { sprintf "%02x", $_ } unpack( 'C*', $mac ) );
    return $mac if $mac =~ /^([0-9A-F][0-9A-F]:){5}[0-9A-F][0-9A-F]$/i;
    return "ERROR";
}

sub _munge_sw_installed_date {
    my $val = shift;

    my ( $y, $m, $d, $hour, $min, $sec ) = unpack( 'n C6 a C2', $val );

    return "$y-$m-$d $hour:$min:$sec";

}

my %ID_VENDOR_MAP = (
    9     => 'Cisco',
    11    => 'HP',
    18    => 'BayRS',
    42    => 'Sun',
    43    => '3Com',
    45    => 'Baystack',
    171   => 'Dell',
    207   => 'Allied',
    244   => 'Lantronix',
    311   => 'Microsoft',
    318   => 'APC',
    674   => 'Dell',
    1872  => 'AlteonAD',
    1916  => 'Extreme',
    1991  => 'Foundry',
    2021  => 'NetSNMP',
    2272  => 'Passport',
    2636  => 'Juniper',
    2925  => 'Cyclades',
    3076  => 'Altiga',
    3224  => 'Netscreen',
    3375  => 'F5',
    3417  => 'BlueCoatSG',
    4526  => 'Netgear',
    5624  => 'Enterasys',
    5951  => 'Netscaler',
    6027  => 'Force10',
    6486  => 'AlcatelLucent',
    6527  => 'Timetra',
    6876  => 'VMWare',
    8072  => 'NetSNMP',
    9303  => 'PacketFront',
    10002 => 'Ubiquiti',
    11898 => 'Orinoco',
    12325 => 'Pf',
    12356 => 'Fortinet',
    12532 => 'Neoteris',
    14179 => 'Airespace',
    14525 => 'Trapeze',
    14823 => 'Aruba',
    14988 => 'Mikrotik',
    17163 => 'Steelhead',
    25506 => 'H3C',
    26543 => 'IBMGbTor',
    30065 => 'Arista',
    35098 => 'Pica8',
);

# Try to extract a vendor string from a sysObjectID.

sub _sysObjectID2vendor {
    my ($id) = @_;
    defined $id or return "NO VENDOR";

    $id =~ /^\.?1\.3\.6\.1\.4\.1\.(\d+)/ and return $ID_VENDOR_MAP{$1};
    return "UNKNOWN";
}

no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
