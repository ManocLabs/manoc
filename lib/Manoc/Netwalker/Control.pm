# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Netwalker::Control;
use Moose;
use namespace::autoclean;

with 'Manoc::Logger::Role';

use IO::Socket;
use POE qw(Wheel::ListenAccept Wheel::ReadWrite);

has config => (
    is       => 'ro',
    isa      => 'Manoc::Netwalker::Config',
    required => 1
);

has device_manager => (
    is       => 'ro',
    isa      => 'Manoc::Netwalker::Manager::Device',
    required => 1,
);

has discover_manager => (
    is       => 'ro',
    isa      => 'Manoc::Netwalker::Manager::Discover',
    required => 1,
);

has server => (
    is  => 'rw',
    isa => 'Ref',
);

has session => (
    isa       => 'POE::Session',
    is        => 'ro',
    required  => 1,
    lazy      => 1,
    builder   => '_build_session',
    clearer   => 'remove_server',
    predicate => 'has_server',
);

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
    $handle or $self->log->logdie("Cannot create control socket");

    # Start the server.
    my $server = POE::Wheel::ListenAccept->new(
        Handle      => $handle,
        AcceptEvent => "on_client_accept",
        ErrorEvent  => "on_server_error",
    );
    $self->server($server);
}

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

sub on_server_error {
    my ( $self, $operation, $errnum, $errstr ) = @_[ OBJECT, ARG0, ARG1, ARG2 ];
    warn "Server $operation error $errnum: $errstr\n";
    $self->server(undef);
}

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

sub on_client_error {
    my $self     = $_[OBJECT];
    my $wheel_id = $_[ARG3];

    # Handle client error, including disconnect.
    $self->remove_client($wheel_id);
}

sub command_status {
    my $self = shift;

    my $scoreboard = $self->manager->scoreboard;
    my $output     = "OK " . scalar( keys(%$scoreboard) ) . " elements";

    while ( my ( $k, $v ) = each(%$scoreboard) ) {
        $output .= "\n$k $v";
    }

    return $output;
}

sub command_enqueue {
    my ( $self, $type, $id ) = @_;

    $type = lc($type);
    if ( $type eq 'device' ) {
        $self->device_manager->enqueue_device($id);
        return "OK added device $id";
    }
    return "ERR unknown object $type";
}

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
