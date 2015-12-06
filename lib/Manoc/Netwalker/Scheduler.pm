# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Netwalker::Scheduler;
use Moose;
use namespace::autoclean;

with 'Manoc::Logger::Role';
use POE;

has config => (
    is       => 'ro',
    isa      => 'Manoc::Netwalker::Config',
    required => 1
);

has manager => (
    is       => 'ro',
    isa      => 'Manoc::Netwalker::Manager',
    required => 1,
);

has session => (
    isa      => 'POE::Session',
    is       => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub {
	POE::Session->create(
	    object_states => [
		$_[0] => [ qw (_start tick ) ]
	    ]
	);
    }
);

has tick_interval => (
    isa      => 'Int',
    is       => 'ro',
    required => 1,
    default  => 10,
);

has refresh_interval => (
    is       => 'ro',
    isa      => 'Int',
    lazy     => 1,
    default  => sub { shift->config->refresh_interval },
);

has schema => (
    is       => 'ro',
    required => 1
);

has next_alarm_time => (
    is       => 'rw',
    isa      => 'Int',
);

sub _start {
    my ($self, $kernel) = @_[OBJECT, KERNEL];

    $self->next_alarm_time(time() + 1);
    $kernel->alarm(tick => $self->next_alarm_time);
}

sub tick {
    my ($self, $kernel) = @_[OBJECT, KERNEL];

    # TODO better check
    my $last_visited = time() - $self->refresh_interval;
    my @devices = $self->schema->resultset('DeviceNWInfo')
	->search({ last_visited => { '<=' => $last_visited }  })
	->get_column('device')->all();

    $self->log->debug("Tick: devices=" . join(',', @devices));
    foreach my $id (@devices) {
	$self->manager->enqueue_device($id);
    }

    $self->next_alarm_time($self->next_alarm_time + $self->tick_interval);
    $kernel->alarm(tick => $self->next_alarm_time);

}

sub BUILD {
    shift->session();
}

no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:

