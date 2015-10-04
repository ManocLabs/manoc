# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Netwalker::Manager;
use Moose;
use namespace::autoclean;

with 'MooseX::Workers';
with 'Manoc::Logger::Role';

use POE qw(Filter::Reference Filter::Line);

use Manoc::Netwalker::DeviceTask;

has config => (
    is       => 'ro',
    isa      => 'Manoc::Netwalker::Config',
    required => 1
);

has 'schema' => (
    is       => 'ro',
    required => 1
);

=head2 worker_stdout

Called when a child prints to STDERR

=cut

sub worker_stderr  {
    my ( $self, $stderr_msg ) = @_;  

    print $stderr_msg,"\n"
}

=head2 worker_stdout

Called when a child prints to STDOUT

=cut

sub worker_stdout  {
    my ( $self, $result ) = @_;

    my $report = Manoc::Netwalker::TaskReport->thaw($result->{report});
    my $host   = $report->host;

    $self->log->debug("Device $host is up to date");
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
    
    my $updater = Manoc::Netwalker::DeviceTask->new({
        schema     => $self->schema,
        config     => $self->config,
        device_id  => $device_id,
    });
    $updater->update;

    print @{
        POE::Filter::Reference->new->put([
            {
                device_id => $device_id,
                report    => $updater->task_report->freeze
            }
        ])
      };
}

        sub visit {
    my $self = shift;
    my $devices = shift;
    
    foreach my $id (@$devices) {
        $self->enqueue( sub {  $self->visit_device($id)  } );
        $self->log->debug("Enqueued device $id");
    }

    POE::Kernel->run();
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
