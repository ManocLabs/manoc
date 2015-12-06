# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::Netwalker::Script;

use Moose;
extends 'Manoc::App';

use POE;

use Manoc::Netwalker::Config;

use Manoc::Netwalker::Manager;
use Manoc::Netwalker::Control;
use Manoc::Netwalker::Scheduler;

sub run {
    my $self = shift;

    $self->log->info("Starting netwalker");

    # get configuration and store it in a Config object
    my %config_args = %{ $self->config->{Netwalker} };
    my $config = Manoc::Netwalker::Config->new(%config_args);

    my $manager = Manoc::Netwalker::Manager->new(
        config  => $config,
        schema  => $self->schema,
    );

    my $control = Manoc::Netwalker::Control->new(
        config  => $config,
        manager => $manager,
    );

    my $scheduler = Manoc::Netwalker::Scheduler->new(
        config  => $config,
        manager => $manager,
        schema  => $self->schema,
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
