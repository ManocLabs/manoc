package App::Manoc::Manifold::Telnet::IOS;
#ABSTRACT: A minimal frontend for CISCO IOS devices still using telnet

use Moose;

##VERSION

=head1 DESCRIPTION

Use this manifold for legacy IOS based devices still accessed via telnet.

At the moment only C<configuration> and C<arp_table> attributes are supported.

=cut

with 'App::Manoc::ManifoldRole::Base',
    'App::Manoc::ManifoldRole::NetDevice',
    'App::Manoc::ManifoldRole::FetchConfig',
    'App::Manoc::Logger::Role';

=head1 CONSUMED ROLES

=for :list
* App::Manoc::ManifoldRole::Base
* App::Manoc::ManifoldRole::NetDevice
* App::Manoc::ManifoldRole::FetchConfig
* App::Manoc::Logger::Role

=cut

use Try::Tiny;
use Net::Telnet::Cisco;
use Regexp::Common qw /net/;

=attr session

Net::Telnet::Cisco session

=cut

has 'session' => (
    is     => 'ro',
    isa    => 'Object',
    writer => '_set_session',
);

=attr username

login user name

=cut

has 'username' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_username',
);

=attr password

first level password

=cut

has 'password' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    lazy     => 1,
    builder  => '_build_password',
);

=attr enable_password

second level password

=cut

has 'enable_password' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_enable_password',
);

sub _build_username {
    my $self = shift;

    return $self->credentials->{username};
}

sub _build_password {
    my $self = shift;
    return $self->credentials->{password} || '';
}

sub _build_eable_password {
    my $self = shift;
    return $self->credentials->{become_password} || '';
}

=method connect

Connect and login in enable mode

=cut

sub connect {
    my $self = shift;

    my $host = self->host;

    #Connect and login in enable mode
    try {
        my $session = Net::Telnet::Cisco->new(
            Host    => $host,
            Timeout => 20,
        );

        $session->login( $self->username, $self->password ) or
            return;

        if ( $self->enable_password ) {
            my $enabled = $session->enable( $self->enable_password );
            if ( !$enabled ) {
                $self->log->error("Cannot enable session");
                return;
            }
        }
        $self->_set_session($session);
        return 1;
    }
    catch {
        $self->log->error("Error connecting to $host: $@");
        return;
    }
}

sub _build_arp_table {
    my $self    = shift;
    my $session = $self->session;

    my %arp_table;

    try {
        my @data = $self->cmd('show ip arp');
        chomp @data;

        # arp entries use to have this format
        # Internet  10.1.2.3   11   00aa.bbcc.ddee  ARPA Interface/0.1
        foreach my $line (@data) {
            $line =~ m/^Internet/ or next;

            my @fields = split m/\s+/, $line;
            $arp_table{ $fields[1] } = $fields[3];
        }

        return \%arp_table;
    };

    $self->log->error('Error fetching configuration');
    return;
}

sub _build_configuration {
    my $self;

    my $session = $self->session;

    try {
        my @data = $session->cmd("show running");
        chomp @data;

        return join( @data, '\n' );
    };
    $self->log->error('Error fetching configuration: $@');
    return;
}

sub _build_boottime { }

sub _build_ifstatus_table { }

sub _build_mat { }

sub _build_model { }

sub _build_name { }

sub _build_os { }

sub _build_os_ver { }

sub _build_serial { }

sub _build_vendor { }

=attr close

Close telnet session.

=cut

sub close {
    shift->session->close();
}

no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
