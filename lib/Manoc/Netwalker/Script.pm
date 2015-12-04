# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::Netwalker::Script;

use Moose;
extends 'Manoc::App';

use Manoc::Netwalker::Config;
use Manoc::Netwalker::Manager;

has 'device' => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

has 'force_full_update' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
);

sub run {
    my $self = shift;

    $self->log->info("Starting netwalker");

    # get configuration and store it in a Config object
    my %config_args = %{ $self->config->{Netwalker} };
    $self->force_full_update and $config_args{force_full_update} = 1;
    my $config = Manoc::Netwalker::Config->new(%config_args);

    # prepare the device (id) list to visit
    my @devices;
    if ($self->device) {
        push @devices, $self->device;
    } else {
        @devices = $self->schema->resultset('Device')->get_column('id')->all;
    }

    my $manager = Manoc::Netwalker::Manager->new(
        schema => $self->schema,
        config => $config,
    );

    $manager->visit( \@devices );
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
