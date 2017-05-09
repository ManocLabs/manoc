package App::Manoc::Netwalker::Control;
#ABSTRACT: Netwalker control interface

=head1 DESCRIPTION

This class implements a control server for Netwalker. It is based on a simple line oriented protocol.

=cut

use Moose;

##VERSION

use namespace::autoclean;

with 'App::Manoc::Logger::Role';

use IO::Socket;
use POE qw(Wheel::ListenAccept Wheel::ReadWrite);

=attr config

Netwalker configuration. Required.

The value in config->control_port can be a port (TCP socket) or a path (UNIX socket)

=cut

has config => (
    is       => 'ro',
    isa      => 'App::Manoc::Netwalker::Config',
    required => 1
);

=attr poller

Reference to poller Workers object. Required.

=cut

has poller => (
    is       => 'ro',
    isa      => 'App::Manoc::Netwalker::Poller::Workers',
    required => 1,
);

=attr poller

Reference to discovery workers object. Required.

=cut

has discoverer => (
    is       => 'ro',
    isa      => 'App::Manoc::Netwalker::Discover::Workers',
    required => 1,
);

=attr server

A L<POE::Wheel::ListenAccept> creating during _start.

=cut

has server => (
    is  => 'rw',
    isa => 'Ref',
);

=attr session

POE session. Required.

=cut

has session => (
    isa       => 'POE::Session',
    is        => 'ro',
    required  => 1,
    lazy      => 1,
    builder   => '_build_session',
    clearer   => 'remove_server',
    predicate => 'has_server',
);

=attr clients

Hash wheel-id to wheel, used by callbacks.

=cut

has clients => (
    traits   => ['Hash'],
    isa      => 'HashRef',
    is       => 'rw',
    lazy     => 1,
    required => 1,
    default  => sub { {} },
    handles  => {
        set_client     => 'set',
        get_client     => 'get',
        remove_client  => 'delete',
        has_client     => 'count',
        num_client     => 'count',
        get_client_ids => 'keys',
    },
);

=function MANOC_CONSOLE_HELLO

Return the welcome message

=cut

sub MANOC_CONSOLE_HELLO { "OK Manoc Netwalker console" }

sub _build_session {
    my $self = shift;

    return POE::Session->create(
        object_states => [
            $self => [
                qw(
                    _start
                    on_client_accept
                    on_server_error
                    on_client_input
                    on_client_error
                    )
            ],
        ],
    );
}

sub _start {
    my ( $self, $job, $args, $kernel, $heap ) = @_[ OBJECT, ARG0, ARG1, KERNEL, HEAP ];

    my $port = $self->config->control_port;

    my $handle;
    if ( $port =~ m|^/| ) {
        # looks like a path, create a UNIX socket
        $handle = IO::Socket::UNIX->new(
            Type   => SOCK_STREAM(),
            Local  => $port,
            Listen => 1,
        );
    }
    else {
        # TCP socket
        $handle = IO::Socket::INET->new(
            LocalPort => $port,
            Listen    => 5,
            ReuseAddr => 1,
        );
    }
    $handle or $self->log->logdie("Cannot create control socket $port: $!");

    # Start the server.
    my $server = POE::Wheel::ListenAccept->new(
        Handle      => $handle,
        AcceptEvent => "on_client_accept",
        ErrorEvent  => "on_server_error",
    );
    $self->server($server);
}

=method on_client_accept

Callback on new client connection.

=cut

sub on_client_accept {
    my ( $self, $client_socket ) = @_[ OBJECT, ARG0 ];
    my $io_wheel = POE::Wheel::ReadWrite->new(
        Handle     => $client_socket,
        InputEvent => "on_client_input",
        ErrorEvent => "on_client_error",
    );

    $io_wheel->put(MANOC_CONSOLE_HELLO);

    $self->set_client( $io_wheel->ID => $io_wheel );
}

=method on_server_error( $operation, $errnum, $errstr )

Callback on server error

=cut

sub on_server_error {
    my ( $self, $operation, $errnum, $errstr ) = @_[ OBJECT, ARG0, ARG1, ARG2 ];
    warn "Server $operation error $errnum: $errstr\n";
    $self->server(undef);
}

=method on_client_input( $input, $wheel_id )

Callback for client input. Parses input line and call the corresponding command_<name> callback.

=cut

sub on_client_input {
    my ( $self, $input, $wheel_id ) = @_[ OBJECT, ARG0, ARG1 ];

    my $client = $self->get_client($wheel_id);

    my @tokens = split( /\s+/, $input );
    my $command = lc( shift @tokens );

    my $handler = "command_$command";
    if ( $self->can($handler) ) {
        my $output = $self->$handler(@tokens);
        $client->put($output);
    }
    elsif ( $command eq 'close' ) {
        $self->remove_client($wheel_id);
    }
    else {
        $client->put("ERR Unknown command $command");
    }
}

=method on_client_error

=cut

sub on_client_error {
    my $self     = $_[OBJECT];
    my $wheel_id = $_[ARG3];

    # Handle client error, including disconnect.
    $self->remove_client($wheel_id);
}

=method command_status

Manages the C<STATUS> command.

=cut

sub command_status {
    my $self = shift;

    my $scoreboard = $self->poller->scoreboard_status;
    my $output     = "OK " . scalar( keys(%$scoreboard) ) . " elements";

    while ( my ( $k, $v ) = each(%$scoreboard) ) {
        $output .= "\n$k $v";
    }

    return $output;
}

=method command_enqueue

Manages the C<ENQUEUE DEVICE|SERVER <id>> command.

=cut

sub command_enqueue {
    my ( $self, $type, $id ) = @_;

    $type = lc($type);
    if ( $type eq 'device' ) {
        $self->poller->enqueue_device($id);
        return "OK added device $id";
    }
    if ( $type eq 'server' ) {
        $self->poller->enqueue_server($id);
        return "OK added server $id";
    }

    return "ERR unknown object $type";
}

=method command_quit

Manages the C<QUIT> command closing the client connection.

=cut

sub command_quit {
    my $self     = $_[OBJECT];
    my $wheel_id = $_[ARG3];

    # Handle client error, including disconnect.
    $self->remove_client($wheel_id);
}

sub BUILD {
    shift->session();
}

no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
