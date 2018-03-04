package App::Manoc::Netwalker::Poller::BaseTask;
#ABSTRACT: Base role for poller tasks

use Moose::Role;
##VERSION

requires "nwinfo";

=attr schema

The Manoc DB schema.

=cut

has 'schema' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1
);

=attr config

Netwalker config object

=cut

has 'config' => (
    is       => 'ro',
    isa      => 'App::Manoc::Netwalker::Config',
    required => 1
);

=attr credentials

Authentication credentials hash.

=cut

has 'credentials' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_credentials',
);

sub _build_credentials {
    my $self = shift;

    my $credentials =
        $self->nwinfo->credentials ? $self->nwinfo->credentials->get_credentials_hash : {};
    $credentials->{snmp_community} ||= $self->config->snmp_community;
    $credentials->{snmp_version}   ||= $self->config->snmp_version;

    return $credentials;
}

=attr refresh_interval

The refresh interval used to compute future scheduling.

=cut

has 'refresh_interval' => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    builder => '_build_refresh_interval',
);

sub _build_refresh_interval {
    shift->config->refresh_interval;
}

=attr timestamp

UNIX timestamp saying the at which the task was started

=cut

has 'timestamp' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub { time },
);

=method reschedule_on_failure

Update C<nwinfo->scheduled_attempt> field after a failed poller attempt.
Implements backoff, doubling interval extent up to C<config->max_backoff>.

=cut

sub reschedule_on_failure {
    my $self   = shift;
    my $nwinfo = $self->nwinfo;

    my $backoff;

    if ( $nwinfo->attempt_backoff ) {
        $backoff = $nwinfo->attempt_backoff * 2;
    }
    else {
        $backoff = $self->config->min_backoff_time;
    }
    $nwinfo->attempt_backoff($backoff);

    my $next_attempt = $self->timestamp + $backoff;
    $nwinfo->scheduled_attempt($next_attempt);
}

=method reschedule_on_success

Update C<nwinfo->scheduled_attempt> field after a successful poller attempt.

=cut

sub reschedule_on_success {
    my $self   = shift;
    my $nwinfo = $self->nwinfo;

    $nwinfo->attempt_backoff(0);
    $nwinfo->scheduled_attempt( $self->timestamp + $self->refresh_interval );
}

no Moose::Role;
1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
