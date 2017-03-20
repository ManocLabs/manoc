# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Netwalker::Poller::Workers;
use Moose;
use namespace::autoclean;

with 'Manoc::Netwalker::WorkersRole',
    'Manoc::Logger::Role';

use Try::Tiny;
use POE qw(Filter::Reference Filter::Line);

use Manoc::Netwalker::Poller::Scoreboard;
use Manoc::Netwalker::Poller::DeviceTask;
use Manoc::Netwalker::Poller::ServerTask;

has scoreboard => (
    is      => 'ro',
    isa     => 'Manoc::Netwalker::Poller::Scoreboard',
    default => sub { Manoc::Netwalker::Poller::Scoreboard->new() },
);


=head2 worker_stdout

Called when a child prints to STDOUT. Used to get status updates from
workers processes.

=cut

sub worker_stdout {
    my ( $self, $task_info, $job_id ) = @_;
    my $class  = $task_info->{class};
    my $id     = $task_info->{id};
    my $status = $task_info->{status};

    $self->log->debug("got feedback class=$class, id=$id status=$status");

    $class eq 'device' and
        $self->scoreboard->set_device_info( $id, $status, $job_id );
    $class eq 'server' and
        $self->scoreboard->set_server_info( $id, $status, $job_id );

    if ( $status eq 'DONE' ) {
        my $report = Manoc::Netwalker::Poller::TaskReport->thaw( $task_info->{report} );
        my $host   = $report->host;
        # TODO check status
        my $has_errors = $report->has_error();
        $self->log->debug("$class $host $status $has_errors");
    }
}

=head2 worker_error

=cut

sub worker_error   {
    my ($self, $job_id) = @_;

    $self->log->warn("Worker error job $job_id");
    $self->scoreboard->delete_job_info($job_id);
}

=head2 worker_finished

=cut

sub worker_finished {
    my ($self, $job_id) = @_;

    $self->log->debug("Job $job_id finished");

    my $info = $self->scoreboard->get_job_info($job_id);
    $info or return;
    my $status =
        $info->[0] eq 'device'
        ?  $self->scoreboard->get_device_status( $info->[1] )
        : $self->scoreboard->get_server_status( $info->[1] );

    defined($status) && $status eq 'RUNNING'
        and $self->log->warn("Job $job_id finished but status was still RUNNING");

    $self->scoreboard->delete_job_info($job_id);
}

=head2 on_tick

Called by the scheduler.

=cut

sub on_tick {
    my ( $self, $kernel ) = @_;

    $self->schedule_devices();
    $self->schedule_servers();
}

=head2 schedule_devices

=cut

sub schedule_devices {
    my $self = shift;

    # TODO better check
    my $now = time();

    my $decommissioned_devices =
        $self->schema->resultset('Device')->search( { decommissioned => 1 } )->get_column('id');

    my @device_ids = $self->schema->resultset('DeviceNWInfo')->search(
        {
            scheduled_attempt => { '<='    => $now },
            device_id         => { -not_in => $decommissioned_devices->as_query }
        }
    )->get_column('device_id')->all();

    $self->log->debug( "on tick: devices to refresh: " . join( ',', @device_ids ) );
    foreach my $id (@device_ids) {

        # check if it's already scheduled
        my $status = $self->scoreboard->get_device_status($id);
        if ( defined($status) && ( $status eq 'QUEUED' || $status eq 'RUNNING' ) ) {
            $self->log->debug("Device $id is $status, skipping");
            next;
        }

        $self->enqueue_device($id);
    }
}

=head2 enqueue_device

=cut

sub enqueue_device {
    my ( $self, $device_id ) = @_;

    $self->scoreboard->set_device_info( $device_id, 'QUEUED' );
    $self->enqueue( sub { $self->visit_device($device_id) } );
    $self->log->debug("Enqueued device $device_id");
}

=head2 visit_device

=cut

sub visit_device {
    my ( $self, $device_id ) = @_;

    my $task_info = {
        class  => 'device',
        id     => $device_id,
        status => 'RUNNING',
    };
    print @{ POE::Filter::Reference->new->put( [$task_info] ) };

    try {
        my $updater = Manoc::Netwalker::Poller::DeviceTask->new(
            {
                schema    => $self->schema,
                config    => $self->config,
                device_id => $device_id,
            }
        );
        $updater->update;


        $task_info->{status} = 'DONE';
        $task_info->{report} = $updater->task_report->freeze;

        undef $updater;
    }
    catch {
        $self->log->error("caught error in device updater: $_");
        $task_info->{status} = 'ERROR';
    };
    print @{ POE::Filter::Reference->new->put( [$task_info] ) };
    $self->log->debug("device updater job for $device_id finished");
}

=head2 schedule_servers

=cut

sub schedule_servers {
    my $self = shift;

    my $now = time();

    my $decommissioned_servers =
        $self->schema->resultset('Server')->search( { decommissioned => 1 } )->get_column('id');

    my @server_ids = $self->schema->resultset('ServerNWInfo')->search(
        {
            scheduled_attempt => { '<='    => $now },
            server_id         => { -not_in => $decommissioned_servers->as_query }
        }
    )->get_column('server_id')->all();

    $self->log->debug( "on tick: servers to refresh: " . join( ',', @server_ids ) );
    foreach my $id (@server_ids) {

        # check if it's already scheduled
        my $status = $self->scoreboard->get_server_status($id);
        if ( defined($status) && ( $status eq 'QUEUED' || $status eq 'RUNNING' ) ) {
            $self->log->debug("Server $id is $status, skipping");
            next;
        }

        $self->enqueue_server($id);
    }
}

=head2 enqueue_server

=cut

sub enqueue_server {
    my ( $self, $server_id ) = @_;

    $self->scoreboard->set_server_info( $server_id, 'QUEUED' );
    $self->enqueue( sub { $self->visit_server($server_id) } );
    $self->log->debug("Enqueued server $server_id");
}

=head2 visit_server

=cut

sub visit_server {
    my ( $self, $server_id ) = @_;

    my $task_info = {
        class  => 'server',
        id     => $server_id,
        status => 'RUNNING',
    };
    print @{ POE::Filter::Reference->new->put( [$task_info] ) };

    try {
        my $updater = Manoc::Netwalker::Poller::ServerTask->new(
            {
                schema    => $self->schema,
                config    => $self->config,
                server_id => $server_id,
            }
        );
        $updater->update;

        $task_info->{status} = 'DONE';
        $task_info->{report} = $updater->task_report->freeze;

        undef $updater;
    }
    catch {
        $self->log->error("caught error in server updater: $_");
        $task_info->{status} = 'ERROR';
    };
    print @{ POE::Filter::Reference->new->put( [$task_info] ) };

    $self->log->debug("server updater job for $server_id finished");

}

no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
