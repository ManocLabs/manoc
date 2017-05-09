package App::Manoc::Netwalker::ControlClient;
#ABSTRACT: Netwalker control protocol client

=head1 DESCRIPTION

This class implements a client connecting to Netwalker control server.

=cut

use Moose;
##VERSION

use namespace::autoclean;

with 'App::Manoc::Logger::Role';

use IO::Socket;
use Moose::Util::TypeConstraints;

=attr config

Netwalker configuration. Required.

=cut

has config => (
    is       => 'ro',
    isa      => 'App::Manoc::Netwalker::Config',
    required => 1
);

=attr status

Current client status.

=cut

has status => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    isa     => enum( [qw[ new connected connection_error protocol_error ]] ),
    default => 'new'
);

has _socket => (
    isa     => 'Maybe[Object]',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_socket',
);

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
        return;
    }

    chomp($line);
    $self->log->debug("Hello from netwalker: $line");
    if ( !$self->check_response($line) ) {
        $self->log->error("Protocol error after connecting netwalker");
        return;
    }

    $self->status("connected");
    return $handle;
}

=method enqueue_device($id)

Send a ENQUEUE DEVICE command to Netwalker

=cut

sub enqueue_device {
    my ( $self, $id ) = @_;

    my $handle = $self->_socket;
    $handle or return;

    $self->log->debug("Enqueue device $id");
    print $handle "ENQUEUE DEVICE $id\n";
    my $response = <$handle>;
    $self->log->debug("Got response from netwalker: $response");

    return $self->_check_response($response);
}

=method enqueue_server($server_id)

Send a ENQUEUE SERVER command to Netwalker

=cut

sub enqueue_server {
    my ( $self, $id ) = @_;

    my $handle = $self->_socket;
    $handle or return;

    $self->log->debug("Enqueue server $id");
    print $handle "ENQUEUE SERVER $id\n";
    my $response = <$handle>;
    $self->log->debug("Got response from netwalker: $response");

    return $self->_check_response($response);
}

sub _check_response {
    my ( $self, $response ) = @_;

    $response =~ /^OK\s/o  and return 1;
    $response =~ /^ERR\s/o and return 0;

    # something went wrong
    $self->status('connection_error');
    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
