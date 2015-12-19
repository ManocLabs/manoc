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
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    mng_address => {
        data_type    => 'varchar',
        is_nullable  => 0,
        size         => 15,
        ipv4_address => 1,
        accessor     => '_mng_address',
    },
    mng_url_format => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
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
    notes => {
        data_type   => 'text',
        is_nullable => 1,
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

__PACKAGE__->has_many(
    neighs => 'Manoc::DB::Result::CDPNeigh',
    { 'foreign.from_device' => 'self.id' },
    {
        cascade_copy   => 0,
        cascade_delete => 0,
        cascade_update => 0,
    }
);

__PACKAGE__->might_have(
    config => 'Manoc::DB::Result::DeviceConfig',
    { 'foreign.device' => 'self.id' },
    {
        cascade_delete => 1,
        cascade_copy   => 0,
    }
);

__PACKAGE__->might_have(
    netwalker_info => 'Manoc::DB::Result::DeviceNWInfo',
    { 'foreign.device' => 'self.id' },
    {
        cascade_delete => 1,
        cascade_copy   => 1,
    }
);

__PACKAGE__->belongs_to(
    mng_url_format => 'Manoc::DB::Result::MngUrlFormat',
    'mng_url_format',
    { join_type => 'LEFT' }
);

sub mng_address {
    my ( $self, $value ) = @_;

    if ( @_ > 1 ) {
        ref($value) or $value = Manoc::IPAddress::IPv4->new($value);
        $self->_mng_address($value);
    }
    return $self->_mng_address();
}

=head2 get_mng_url

Return mng_address formatted using mng_url_format,

=cut

sub get_mng_url {
    my $self = shift;

    my $format = $self->mng_url_format;
    return unless $format;

    my $str    = $format->format;
    my $ipaddr = $self->mng_address->unpadded;
    $str =~ s/%h/$ipaddr/go;

    return $str;
}

=head2 get_config_date

Return the date of the last saved config, undef if there isn't any

=cut

sub get_config_date {
    my $self = shift;

    my $config = $self->config;
    $config or return undef;
    return $config->config_date;
}

=head2 update_config( $config_text, [ $timestamp ] )

Create or update the related DeviceConfig object. Check if configuration has changed before rotating the stored one.
Return 1 if the config object has been refreshed, undef otherwise.

=cut

sub update_config {
    my ( $self, $config_text, $timestamp ) = @_;

    $timestamp ||= time;

    my $config = $self->config;
    if ( !$config ) {
        $self->create_related(
            'config' => {
                config      => $config_text,
                config_date => $timestamp,
            }
        );

        return 1;
    }

    if ( $config->config ne $config_text ) {
        $config->prev_config( $config->config );
        $config->prev_config_date( $config->config_date );
        $config->config($config_text);
        $config->config_date($timestamp);
        $config->update();

        return 1;
    }

    return;
}

1;
