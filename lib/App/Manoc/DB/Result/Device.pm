# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::DB::Result::Device;

use parent 'App::Manoc::DB::Result';

use strict;
use warnings;

__PACKAGE__->load_components(qw/+App::Manoc::DB::InflateColumn::IPv4/);

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
    mng_url_format_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },
    hwasset_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },

    name => {
        data_type     => 'varchar',
        size          => 128,
        default_value => 'NULL',
        is_nullable   => 1,
    },

    rack_id => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },
    rack_level => {
        data_type   => 'int',
        is_nullable => 1,
    },

    decommissioned => {
        data_type     => 'int',
        size          => '1',
        default_value => '0',
    },

    decommission_ts => {
        data_type     => 'int',
        default_value => 'NULL',
        is_nullable   => 1,
    },

    notes => {
        data_type   => 'text',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [qw/id/] );
__PACKAGE__->add_unique_constraint( [qw/mng_address/] );

__PACKAGE__->belongs_to(
    hwasset => 'App::Manoc::DB::Result::HWAsset',
    'hwasset_id',
    { join_type => 'left' }
);

__PACKAGE__->belongs_to(
    rack => 'App::Manoc::DB::Result::Rack',
    'rack_id',
    { join_type => 'left' }
);

sub rack {
    my ( $self, @args ) = @_;

    if (@args) {
        my $rack = $args[0];
        if ( $rack && $self->hwasset ) {
            $self->hwasset->rack($rack);
        }
    }

    $self->next::method(@args);
}

__PACKAGE__->has_many(
    ifstatus => 'App::Manoc::DB::Result::IfStatus',
    'device_id'
);

__PACKAGE__->has_many(
    uplinks => 'App::Manoc::DB::Result::Uplink',
    'device_id'
);
__PACKAGE__->has_many(
    ifnotes => 'App::Manoc::DB::Result::IfNotes',
    'device_id'
);
__PACKAGE__->has_many(
    ssids => 'App::Manoc::DB::Result::SSIDList',
    'device_id'
);
__PACKAGE__->has_many(
    dot11clients => 'App::Manoc::DB::Result::Dot11Client',
    'device_id'
);
__PACKAGE__->has_many(
    dot11assocs => 'App::Manoc::DB::Result::Dot11Assoc',
    'device_id'
);
__PACKAGE__->has_many(
    mat_assocs => 'App::Manoc::DB::Result::Mat',
    'device_id'
);

__PACKAGE__->has_many(
    neighs => 'App::Manoc::DB::Result::CDPNeigh',
    { 'foreign.from_device_id' => 'self.id' },
    {
        cascade_copy   => 0,
        cascade_delete => 0,
        cascade_update => 0,
    }
);

__PACKAGE__->might_have(
    config => 'App::Manoc::DB::Result::DeviceConfig',
    { 'foreign.device_id' => 'self.id' },
    {
        cascade_delete => 1,
        cascade_copy   => 0,
    }
);

__PACKAGE__->might_have(
    netwalker_info => 'App::Manoc::DB::Result::DeviceNWInfo',
    { 'foreign.device_id' => 'self.id' },
    {
        cascade_delete => 1,
        cascade_copy   => 1,
    }
);

__PACKAGE__->belongs_to(
    mng_url_format => 'App::Manoc::DB::Result::MngUrlFormat',
    'mng_url_format_id',
    { join_type => 'LEFT' }
);

sub mng_address {
    my ( $self, $value ) = @_;

    if ( @_ > 1 ) {
        ref($value) or $value = App::Manoc::IPAddress::IPv4->new($value);
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

Create or update the related DeviceConfig object. Check if
configuration has changed before rotating the stored one.  Return 1 if
the config object has been refreshed, undef otherwise.

=cut

sub update_config {
    my ( $self, $config_text, $timestamp ) = @_;

    defined($config_text) or
        return;

    $timestamp ||= time;

    my $config = $self->config;
    if ( !$config ) {
        $config = $self->create_related(
            'config' => {
                config      => $config_text,
                config_date => $timestamp,
            }
        );
        $self->config($config);

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

=head2 decommission([$timestamp])

Set decommissioned to true, update timestamp and deassociate nwinfo if
needed.

=cut

sub decommission {
    my $self = shift;
    my $timestamp = shift // time();

    $self->decommissioned and return;

    my $guard = $self->result_source->schema->txn_scope_guard;

    $self->decommissioned(1);
    $self->decommission_ts($timestamp);
    $self->hwasset(undef);
    if ( $self->netwalker_info ) {
        $self->netwalker_info->delete();
    }
    $self->update;

    $guard->commit;
}

=head2 reactivate

Set decommissioned to false and reset timestamp.

=cut

sub restore {
    my $self = shift;

    return unless $self->decommissioned;

    $self->decommissioned(0);
    $self->decommission_ts(undef);
}

=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
