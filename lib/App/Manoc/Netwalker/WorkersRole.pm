package App::Manoc::Netwalker::WorkersRole;
use Moose::Role;
##VERSION

use namespace::autoclean;

with 'MooseX::Workers';
with 'App::Manoc::Logger::Role';

use Try::Tiny;
use POE qw(Filter::Reference Filter::Line);

requires 'on_tick';

has config => (
    is       => 'ro',
    isa      => 'App::Manoc::Netwalker::Config',
    required => 1
);

has schema => (
    is       => 'ro',
    required => 1
);

sub BUILD {
    my $self = shift;

    $self->max_workers( $self->config->n_procs );
}

=head2 worker_stderr

Called when a child prints to STDERR

=cut

sub worker_stderr {
    my ( $self, $stderr_msg ) = @_;
    print STDERR "$stderr_msg\n";
}

=head2 worker_stdout

Called when a child prints to STDOUT

=cut

sub worker_stdout {
    my ( $self, $result ) = @_;

    # pass
}

=head2 stdout_filter

Returns the POE::Filter to be used for stdout.

=cut

sub stdout_filter { POE::Filter::Reference->new }

=head2 stderr_filter

Returns the POE::Filter to be used for stderr.

=cut

sub stderr_filter { POE::Filter::Line->new }

no Moose::Role;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
