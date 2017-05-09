package App::Manoc::Script::Daemon;
use Moose;

##VERSION

# it must be a class in order to override foreground
extends 'App::Manoc::Script';
with 'MooseX::Daemonize';

=method main

Just a place holder: this method MUST be overriden by actual daemon class.

=cut

sub main {
    die "This method must be overridden";
}

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

has cmd_status => (
    metaclass => 'Getopt',
    cmd_flag  => 'status',
    isa       => 'Bool',
    is        => 'ro',
    default   => sub { 0 },

    documentation => 'get daemon status',
);

=method run

The script entry point.

The following command lines are supported beside the one from
L<MooseX::Daemonize> and L<App::Manoc::Script>.

=for :list
* -k or --stop to terminate the daemon
* --status to get info

Process stay on foreground when started in debug mode.

=cut

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
