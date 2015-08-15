# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::Device;

use parent 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->load_components(qw/+Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('devices');
__PACKAGE__->add_columns(
    id => {
        data_type   => 'int',
        is_nullable => 0,
    },
    mng_address => {
	data_type   => 'varchar',
	is_nullable => 0,
	size        => 15,
	ipv4_address => 1,
    },
    rack => {
        data_type      => 'int',
        is_nullable    => 0,
        is_foreign_key => 1,
    },
    level => {
        data_type   => 'int',
        is_nullable => 0,
    },
    name => {
        data_type     => 'varchar',
        size          => 128,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    model => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    serial => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    vendor => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    os => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    os_ver => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    vtp_domain => {
        data_type     => 'varchar',
        size          => 64,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    boottime => {
        data_type     => 'int',
        default_value => '0',
    },
    last_visited => {
        data_type     => 'int',
        default_value => '0',
    },
    offline => {
        data_type     => 'int',
        size          => 1,
        default_value => '0',
    },
    notes => {
        data_type   => 'text',
        is_nullable => 1,
    },
    telnet_pwd => {
        data_type     => 'varchar',
        size          => 255,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    enable_pwd => {
        data_type     => 'varchar',
        size          => 255,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    snmp_com => {
        data_type     => 'varchar',
        size          => 255,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    snmp_user => {
        data_type     => 'varchar',
        size          => 50,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    snmp_password => {
        data_type     => 'varchar',
        size          => 50,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    snmp_ver => {
        data_type     => 'int',
        size          => 1,
        default_value => '0',
    },
    backup_enable => {
        accessor      => 'backup_enabled',
        data_type     => 'int',
        size          => 1,
        default_value => '0',
    },
    get_arp => {
        data_type     => 'int',
        size          => 1,
        default_value => '0',
    },
    get_mat => {
        data_type     => 'int',
        size          => 1,
        default_value => '0',
    },
    get_dot11 => {
        data_type     => 'int',
        size          => 1,
        default_value => '0',
    },
    mat_native_vlan => {
        data_type     => 'int',
        default_value => '1',
        is_nullable   => 1,
    },
    vlan_arpinfo => {
        data_type     => 'int',
        default_value => 'NULL',
        is_nullable   => 1,
    },
    mng_url_format => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [qw/id/] );
__PACKAGE__->add_unique_constraint( [qw/mng_address/] );

__PACKAGE__->belongs_to( rack => 'Manoc::DB::Result::Rack' );
__PACKAGE__->has_many( ifstatus     => 'Manoc::DB::Result::IfStatus' );
__PACKAGE__->has_many( uplinks      => 'Manoc::DB::Result::Uplink' );
__PACKAGE__->has_many( ifnotes      => 'Manoc::DB::Result::IfNotes' );
__PACKAGE__->has_many( ssids        => 'Manoc::DB::Result::SSIDList' );
__PACKAGE__->has_many( dot11clients => 'Manoc::DB::Result::Dot11Client' );
__PACKAGE__->has_many( dot11assocs  => 'Manoc::DB::Result::Dot11Assoc' );
__PACKAGE__->has_many( mat_assocs   => 'Manoc::DB::Result::Mat' );

__PACKAGE__->belongs_to( mat_native_vlan => 'Manoc::DB::Result::Vlan' );
__PACKAGE__->belongs_to( vlan_arpinfo    => 'Manoc::DB::Result::Vlan' );

__PACKAGE__->has_many(
    neighs => 'Manoc::DB::Result::CDPNeigh',
    { 'foreign.from_device' => 'self.id' },
    { delete_cascade        => 0 }
);

__PACKAGE__->might_have(
    config => 'Manoc::DB::Result::DeviceConfig',
    { 'foreign.device' => 'self.id' },
    {
        cascade_delete => 1,
        cascade_copy   => 1,
    }
);

__PACKAGE__->belongs_to(
    mng_url_format => 'Manoc::DB::Result::MngUrlFormat',
    'mng_url_format',
    { join_type => 'left' }
);


sub get_mng_url {
    my $self = shift;

    my $format = $self->mng_url_format;
    return unless $format;

    my $str    = $format->format;
    my $ipaddr = $self->mng_address->address;
    $str =~ s/%h/$ipaddr/go;

    return $str;
}

1;
