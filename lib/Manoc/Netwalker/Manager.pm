# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Netwalker::Manager;
use Moose;
use namespace::autoclean;

with 'MooseX::Workers';
with 'Manoc::Logger::Role';

use Try::Tiny;
use POE qw(Filter::Reference Filter::Line);

use Manoc::Netwalker::DeviceTask;

has config => (
    is       => 'ro',
    isa      => 'Manoc::Netwalker::Config',
    required => 1
);

has schema => (
    is       => 'ro',
    required => 1
);

has scoreboard => (
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { {} },
);

=head2 worker_stdout

Called when a child prints to STDERR

=cut

sub worker_stderr  {
    my ( $self, $stderr_msg ) = @_;
    print STDERR "$stderr_msg\n";
}

=head2 worker_stdout

Called when a child prints to STDOUT

=cut

sub worker_stdout  {
    my ( $self, $result ) = @_;

    my $device_id = $result->{device_id};
    my $status    = $result->{status};
    $self->log->debug("got feedback device=$device_id status=$status");

    $self->scoreboard->{$device_id} = $status;

    if ($status eq 'DONE' ) {
        my $report = Manoc::Netwalker::TaskReport->thaw($result->{report});
        my $host   = $report->host;
        # TODO check status
        my $has_errors = $report->has_error();
        $self->log->debug("Device $host $status $has_errors");
    }
}

=head2 stdout_filter

Returns the POE::Filter to be used for stdout.

=cut

sub stdout_filter  { POE::Filter::Reference->new }

=head2 stderr_filter

Returns the POE::Filter to be used for stderr.

=cut

sub stderr_filter  { POE::Filter::Line->new }

sub visit_device {
    my ($self, $device_id) = @_;

    my $task_info = {
        device_id => $device_id,
        status    => 'RUNNING',
    };
    print @{ POE::Filter::Reference->new->put([ $task_info ]) };

    try {
        my $updater = Manoc::Netwalker::DeviceTask->new({
            schema     => $self->schema,
            config     => $self->config,
            device_id  => $device_id,
        });
        $updater->update;

        $task_info->{status} = 'DONE';
        $task_info->{report} = $updater->task_report->freeze;
    } catch {
        $task_info->{status} = 'ERROR';
    };
    print @{ POE::Filter::Reference->new->put([ $task_info ]) };
}

sub enqueue_device {
    my ($self, $device_id) = @_;

    my $scoreboard = $self->scoreboard;

    # check if it's already scheduled
    my $status = $scoreboard->{$device_id};
    if ($status eq 'QUEUED' || $status eq 'RUNNING') {
        $self->log->debug("Device $device_id is $status, skipping");
        return;
    }

    $self->scoreboard->{$device_id} = 'QUEUED';
    $self->enqueue( sub {  $self->visit_device($device_id)  } );
    $self->log->debug("Enqueued device $device_id");
}


sub BUILD {
    my $self = shift;

    $self->max_workers($self->config->n_procs);
}


no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
