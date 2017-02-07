# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Netwalker::Manager::Device;
use Moose;
use namespace::autoclean;

with 'Manoc::Netwalker::Manager';
with 'Manoc::Logger::Role';

use Try::Tiny;
use POE qw(Filter::Reference Filter::Line);

use Manoc::Netwalker::DeviceTask;

has scoreboard => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has refresh_interval => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    builder => '_build_refresh_interval',
);

sub _build_refresh_interval {
    shift->config->refresh_interval;
}

=head2 worker_stdout

Called when a child prints to STDOUT

=cut

sub worker_stdout {
    my ( $self, $result ) = @_;

    my $device_id = $result->{device_id};
    my $status    = $result->{status};
    $self->log->debug("got feedback device=$device_id status=$status");

    $self->scoreboard->{$device_id} = $status;

    if ( $status eq 'DONE' ) {
        my $report = Manoc::Netwalker::TaskReport->thaw( $result->{report} );
        my $host   = $report->host;
        # TODO check status
        my $has_errors = $report->has_error();
        $self->log->debug("Device $host $status $has_errors");
    }
}

=head2 on_tick

Called by the scheduler.

=cut

sub on_tick {
    my ( $self, $kernel ) = @_;

    # TODO better check
    my $last_visited = time() - $self->refresh_interval;

    my $decommissioned_devices =
        $self->schema->resultset('Device')->search( { decommissioned => 1 } )->get_column('id');

    my @device_ids = $self->schema->resultset('DeviceNWInfo')->search(
        {
            last_visited => { '<='    => $last_visited },
            device_id    => { -not_in => $decommissioned_devices->as_query }
        }
    )->get_column('device_id')->all();

    $self->log->debug( "on tick: devices to refresh: " . join( ',', @device_ids ) );
    foreach my $id (@device_ids) {

        # check if it's already scheduled
        my $status = $self->scoreboard->{$id};
        if ( defined($status) && ( $status eq 'QUEUED' || $status eq 'RUNNING' ) ) {
            $self->log->debug("Device $id is $status, skipping");
            next;
        }

        $self->enqueue_device($id);
    }
}

sub enqueue_device {
    my ( $self, $device_id ) = @_;

    $self->scoreboard->{$device_id} = 'QUEUED';
    $self->enqueue( sub { $self->visit_device($device_id) } );
    $self->log->debug("Enqueued device $device_id");
}

sub visit_device {
    my ( $self, $device_id ) = @_;

    my $task_info = {
        device_id => $device_id,
        status    => 'RUNNING',
    };
    print @{ POE::Filter::Reference->new->put( [$task_info] ) };

    try {
        my $updater = Manoc::Netwalker::DeviceTask->new(
            {
                schema    => $self->schema,
                config    => $self->config,
                device_id => $device_id,
            }
        );
        $updater->update;

        $task_info->{status} = 'DONE';
        $task_info->{report} = $updater->task_report->freeze;
    }
    catch {
        $self->log->error("caught error in device updater: $_");
        $task_info->{status} = 'ERROR';
    };
    print @{ POE::Filter::Reference->new->put( [$task_info] ) };
}

no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
