# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Netwalker::ControlClient;
use Moose;
use namespace::autoclean;

use IO::Socket;
use Moose::Util::TypeConstraints;

with 'App::Manoc::Logger::Role';

has config => (
    is       => 'ro',
    isa      => 'App::Manoc::Netwalker::Config',
    required => 1
);

has socket => (
    isa     => 'Maybe[Object]',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_socket',
);

has status => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    isa     => enum( [qw[ new connected connection_error protocol_error ]] ),
    default => 'new'
);

sub check_response {
    my ( $self, $response ) = @_;

    $response =~ /^OK\s/o  and return 1;
    $response =~ /^ERR\s/o and return 0;

    # something went wrong
    $self->status('connection_error');
    return undef;
}

sub _build_socket {
    my $self = shift;

    my $port = $self->config->control_port;

    my $handle;
    if ( $port =~ m|^/| ) {
        # looks like a path, create a UNIX socket
        $handle = IO::Socket::UNIX->new(
            Peer => $port,
            Type => SOCK_STREAM(),

        );
    }
    else {
        # TCP socket
        $handle = IO::Socket::INET->new(
            PeerAddr => $self->config->remote_control,
            PeerPort => $port,
            Proto    => 'tcp',
        );
    }

    if ( !$handle ) {
        $self->log->error("Can't connect to netwalker control port");
        $self->status("connection_error");
        return;
    }

    my $line = <$handle>;
    if ( !defined($line) ) {
        $self->log->error("Protocol error after connecting netwalker");
        return undef;
    }

    chomp($line);
    $self->log->debug("Hello from netwalker: $line");
    if ( !$self->check_response($line) ) {
        $self->log->error("Protocol error after connecting netwalker");
        return undef;
    }

    $self->status("connected");
    return $handle;
}

sub enqueue_device {
    my ( $self, $id ) = @_;

    my $handle = $self->socket;
    $handle or return undef;

    $self->log->debug("Enqueue device $id");
    print $handle "ENQUEUE DEVICE $id\n";
    my $response = <$handle>;
    $self->log->debug("Got response from netwalker: $response");

    return $self->check_response($response);
}

sub enqueue_server {
    my ( $self, $id ) = @_;

    my $handle = $self->socket;
    $handle or return undef;

    $self->log->debug("Enqueue server $id");
    print $handle "ENQUEUE SERVER $id\n";
    my $response = <$handle>;
    $self->log->debug("Got response from netwalker: $response");

    return $self->check_response($response);
}

no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
