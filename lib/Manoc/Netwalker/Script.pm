# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::Netwalker::Script;

use Moose;
extends 'Manoc::Script::Daemon';

use POE;

use Manoc::Netwalker::Config;
use Manoc::Netwalker::Control;
use Manoc::Netwalker::Scheduler;
use Manoc::Netwalker::Manager::Discover;
use Manoc::Netwalker::Manager::Device;

sub main {
    my $self = shift;

    $self->log->info("Starting netwalker");

    # get configuration and store it in a Config object
    my %config_args = %{ $self->config->{Netwalker} || {} };
    $config_args{manoc_config_dir} ||= $self->manoc_config_dir;

    my $config = Manoc::Netwalker::Config->new(%config_args);

    my $device_manager = Manoc::Netwalker::Manager::Device->new(
        config => $config,
        schema => $self->schema,
    );

    my $discover_manager = Manoc::Netwalker::Manager::Discover->new(
        config => $config,
        schema => $self->schema,
    );

    my $scheduler = Manoc::Netwalker::Scheduler->new(
        config => $config,
        schema => $self->schema,
    );
    $scheduler->add_workers_manager($device_manager);
    $scheduler->add_workers_manager($discover_manager);

    my $control = Manoc::Netwalker::Control->new(
        config           => $config,
        device_manager   => $device_manager,
        discover_manager => $discover_manager,
    );

    POE::Kernel->run();
}

# Clean up the namespace.
no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
