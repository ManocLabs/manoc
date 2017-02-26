package Manoc::Netwalker::Poller::Scoreboard;

use Moose;
use Moose::Util::TypeConstraints;

enum 'TaskStatus', [qw(DONE QUEUED RUNNING ERROR)];

has _scoreboard => (
    is      => 'ro',
    isa     => 'HashRef[HashRef[TaskStatus]]',
    default => sub { {} },
);


=head2 get_device

=cut

sub get_device { shift->_get('device', @_) }

=head2 set_device

=cut

sub set_device { shift->_set('device', @_) }

=head2 device_status_list

=cut

sub device_status_list{ shift->_scoreboard->{device} }

=head2 get_server

=cut

sub get_server { shift->_get('server', @_) }

=head2 set_server

=cut

sub set_server { shift->_set('server', @_) }

=head2 server_status_list

=cut

sub server_status_list { shift->_scoreboard->{server} }

# private methods

sub _set {
    my ($self, $class, $id, $value) = @_;

    return $self->_scoreboard->{$class}->{$id} = $value;
}

sub _get {
    my ($self, $class, $id) = @_;

    return $self->_scoreboard->{$class}->{$id};
}


no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
