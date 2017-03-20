package Manoc::Netwalker::Poller::Scoreboard;

use Moose;
use Moose::Util::TypeConstraints;

enum 'TaskStatus', [qw(DONE QUEUED RUNNING ERROR)];

has _status => (
    is      => 'ro',
    isa     => 'HashRef[HashRef[TaskStatus]]',
    default => sub { {} },
);


has _job => (
    is      => 'ro',
    isa     => 'HashRef[ArrayRef]',
    default => sub { {} },
);

=head2 get_device_status( $id )

=cut

sub get_device_status { shift->_get( 'device', @_ ) }

=head2 set_device_info( $id, $status, $jobid )

=cut

sub set_device_info { shift->_set( 'device', @_ ) }

=head2 device_status_list

=cut

sub device_status_list { shift->_status->{device} }

=head2 get_server_status

=cut

sub get_server_status { shift->_get( 'server', @_ ) }

=head2 set_server_info

=cut

sub set_server_info { shift->_set( 'server', @_ ) }

=head2 server_status_list

=cut

sub server_status_list { shift->_status->{server} }

=head2 get_job_info

=cut

sub get_job_info {
    my ( $self, $job_id) = @_;

    return $self->_job->{$job_id};
}

=head2 delete_job_info

=cut

sub delete_job_info {
    my ( $self, $job_id) = @_;

    my $info = $self->_job->{$job_id};

    if ($info) {
        my ($class, $id) = @$info;
        delete $self->_status->{$class}->{$id};
        delete $self->_job->{$job_id};
    }
}


# private methods

sub _set {
    my ( $self, $class, $id, $value, $job_id ) = @_;

    defined($job_id) and $self->_job->{$job_id} = [ $class, $id ];
    return $self->_status->{$class}->{$id} = $value;

}

sub _get {
    my ( $self, $class, $id ) = @_;

    return $self->_status->{$class}->{$id};
}

no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
