# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package App::Manoc::Netwalker::Poller::BaseTask;

use Moose::Role;

has 'schema' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1
);

has 'config' => (
    is       => 'ro',
    isa      => 'App::Manoc::Netwalker::Config',
    required => 1
);


has 'credentials' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_credentials',
);

sub _build_credentials {
    my $self = shift;

    my $credentials = $self->nwinfo->get_credentials_hash;
    $credentials->{snmp_community} ||= $self->config->snmp_community;
    $credentials->{snmp_version}   ||= $self->config->snmp_version;

    return $credentials;
}

has refresh_interval => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    builder => '_build_refresh_interval',
);

sub _build_refresh_interval {
    shift->config->refresh_interval;
}


has 'timestamp' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub { time },
);

sub reschedule_on_failure {
    my $self = shift;
    my $nwinfo = $self->nwinfo;

    my $backoff;

    if ($nwinfo->attempt_backoff) {
        $backoff = $nwinfo->attempt_backoff * 2;
    } else {
        $backoff = $self->config->min_backoff_time;
    }
    $nwinfo->attempt_backoff($backoff);

    my $next_attempt = $self->timestamp + $backoff;
    $nwinfo->scheduled_attempt( $next_attempt );
}

sub reschedule_on_success {
    my $self = shift;
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
