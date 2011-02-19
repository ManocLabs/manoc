# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::App::Netwalker;

use Moose;
extends 'Manoc::App';

use Manoc::Netwalker::DeviceUpdater;

has 'device' => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

has 'debug' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub run {
    my $self = shift;

    $self->log->info("Starting netwalker");

    # test code
    $self->device or die "Missing device";

    my @device_ids = $self->schema->resultset('Device')->get_column('id')->all;
    my %device_set = map { $_ => 1 } @device_ids;

    my %config = (
        snmp_community     => $self->config->{Credentials}->{snmp_community}   || 'public',
        snmp_version       => '2c',
        default_vlan       => $self->config->{Netwalker}->{default_vlan}       || 1,
        iface_filter       => $self->config->{Netwalker}->{iface_filter}       || 1,
        ignore_portchannel => $self->config->{Netwalker}->{ignore_portchannel} || 1,
    );

    my $device_entry = $self->schema->resultset('Device')->find( $self->device );
    $device_entry or $self->log->logdie( $self->device, " not in device list" );

    my $updater = Manoc::Netwalker::DeviceUpdater->new(
        entry      => $device_entry,
        config     => \%config,
        device_set => \%device_set,
        schema     => $self->schema,
        timestamp  => time
    );
    $updater->update_all_info();
    print $updater->report->freeze;
}

no Moose;    # Clean up the namespace.
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
