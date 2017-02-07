# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::ManifoldRole::SSH;

use Moose::Role;
with 'Manoc::ManifoldRole::Base';
with 'Manoc::Logger::Role';

use Net::OpenSSH;

has 'username' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_username'
);

has 'key_path' => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_key_path'
);

has 'password' => (
    is      => 'rw',
    isa     => 'Str',
    builder => '_build_password'

);

has 'session' => (
    is  => 'rw',
    isa => 'Object'
);

sub _build_username {
    my $self = shift;

    return $self->credentials->{username};
}

sub _build_use_ssh_key {
    my $self = shift;

    return $self->credentials->{use_ssh_key};
}

sub _build_key_path {
    my $self = shift;

    return $self->credentials->{key_path};
}

sub _build_password {
    my $self = shift;
    return $self->credentials->{password} || '';
}

sub cmd {
    my $self    = shift;
    my $session = $self->session;
    return $session->capture(@_);
}

sub connect {
    my $self = shift;

    $ENV{MANOC_DEBUG_SSH} and $Net::OpenSSH::debug = -1;

    my $host = $self->host;

    my %opts;
    $opts{user} = $self->username;
    if ( $self->use_ssh_key ) {
        $opts{key_path} = $self->key_path;
    }
    else {
        $opts{password} = $self->password;
    }
    # Disables querying the user for password and passphrases.
    $opts{batch_mode} = 1;

    my $ssh = Net::OpenSSH->new( $host, %opts );
    if ( $ssh->error ) {
        $self->log->error( "Could not connect to $host: " . $ssh->error );
        return undef;
    }
    $self->session($ssh);
    return 1;
}

sub get_error {
    my $self = shift;

    return $self->session->error;
}

sub close {
    my $self = shift;

    $self->session(undef);
}

no Moose::Role;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
