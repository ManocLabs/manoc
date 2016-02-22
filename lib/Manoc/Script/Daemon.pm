# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Script::Daemon;
use Moose;

# it must be a class in order to override foreground
extends 'Manoc::Script';
with 'MooseX::Daemonize';

sub main {
    die "This method must be overridden";
}

# use -f to start in foreground

# -k or --stop to terminate the daemon
has cmd_stop => (
    metaclass   => 'Getopt',
    cmd_flag    => 'stop',
    cmd_aliases => 'k',
    isa         => 'Bool',
    is          => 'ro',
    default     => sub { 0 },

    documentation => 'kill the daemon',
);

has '+foreground' => ( writer => '_set_foreground', );

# --status to get info
has cmd_status => (
    metaclass => 'Getopt',
    cmd_flag  => 'status',
    isa       => 'Bool',
    is        => 'ro',
    default   => sub { 0 },

    documentation => 'get daemon status',
);

sub run {
    my $self = shift;

    # when in foreground mode do not run Daemonize stuff
    # just call the main method
    if ( $self->foreground ) {
        return $self->main;
    }

    if ( $self->cmd_stop ) {
        $self->stop;
    }
    elsif ( $self->cmd_status ) {
        $self->status;
    }
    else {
        # when in debug mode do not fork
        $self->debug and $self->_set_foreground(1);

        $self->start;
    }

    print $self->status_message, "\n";
    exit( $self->exit_code );
}

after 'start' => sub {
    my $self = shift;
    return unless $self->is_daemon;
    $self->main;
};
# Clean up the namespace.
no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
