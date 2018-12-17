package App::Manoc::Script::Daemon;
use Moose;

use POSIX qw(setuid setgid);
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

has '+foreground' => ( writer => '_set_foreground', default => 0 );

has cmd_status => (
    metaclass => 'Getopt',
    cmd_flag  => 'status',
    isa       => 'Bool',
    is        => 'ro',
    default   => sub { 0 },

    documentation => 'get daemon status',
);

has user => (
    metaclass => 'Getopt',
    isa       => 'Str',
    is        => 'ro',
    default   => sub { 0 },

    documentation => 'set daemon user',
);

has group => (
    metaclass => 'Getopt',
    isa       => 'Str',
    is        => 'ro',
    default   => sub { 0 },

    documentation => 'set daemon group',
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
        $self->log->debug("Start in foreground");
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
        if ( $self->debug ) {
            $self->log->debug("Setting foreground because of debug");
            $self->_set_foreground(1);
        }
        $self->start;
    }

    print $self->status_message, "\n";
    exit( $self->exit_code );
}

after 'start' => sub {
    my $self = shift;

    return unless $self->is_daemon;

    $self->log->debug("Dropping privileges (if setted)");
    $self->drop_privileges;

    $self->log->debug("Running main server loop");
    $self->main;
};

=method drop_privileges

Set gid and uid according to user and group options.
If defined call the before_set_user callback.

=cut

sub drop_privileges {
    my $self = shift;

    $self->can('before_set_user') and $self->before_set_user;

    if ( my $group = $self->group ) {
        my $gid = getgrnam( $self->group );
        $gid or $self->log->logdie("Cannot identify group $group ");
        setgid($gid) or
            $self->log->logdie("Cannot set group $group ");
        $self->log->debug("setgid($gid)");
    }

    if ( my $user = $self->user ) {
        my $uid = getpwnam($user);
        $uid or $self->log->logdie("Cannot identify user $user ");

        setuid($uid) or
            $self->log->logdie("Cannot set user $user ");

        $ENV{USER} = $user;
        $ENV{HOME} = ( ( getpwuid($uid) )[7] );

        $self->log->debug("setuid($uid)");
        $self->log->debug( "\$ENV{USER} => " . $ENV{USER} );
        $self->log->debug( "\$ENV{HOME} => " . $ENV{HOME} );
    }

}

# Clean up the namespace.
no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
