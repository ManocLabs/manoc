package App::Manoc;
#ABSTRACT: Network monitoring application

use Moose;

##VERSION

use namespace::autoclean;

require 5.10.1;
use version 0.77;    # even for Perl v.5.10.0

use Catalyst::Runtime 5.90;

use App::Manoc::DB;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    ConfigLoader

    Static::Simple

    Authentication

    Session
    Session::Store::DBI
    Session::State::Cookie

    +App::Manoc::CatalystRole::RequestToken
    +App::Manoc::CatalystRole::Permission

    StackTrace
    /;

extends 'Catalyst';

with 'App::Manoc::Logger::CatalystRole';
with 'Catalyst::ClassData';

__PACKAGE__->mk_classdata("plugin_registry");
__PACKAGE__->plugin_registry( {} );

# Configure the application.
#
# Note that settings in manoc.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'App::Manoc',

    # Views setup
    default_view => 'TT',

    use_request_uri_for_path => 1,

    'Model::ManocDB' => $App::Manoc::DB::DEFAULT_CONFIG,

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,

    'Plugin::Authentication' => {
        default_realm => 'userdb',
        realms        => {
            userdb => {
                credential => {
                    class          => 'Password',
                    password_field => 'password',
                    password_type  => 'self_check',
                },
                store => {
                    class       => 'DBIx::Class',
                    user_model  => 'ManocDB::User',
                    role_column => 'roles',
                },
            },
            agent => {
                credential => {
                    class          => 'HTTP',
                    type           => 'basic',
                    password_field => 'password',
                    password_type  => 'self_check',
                },
                store => {
                    class       => 'DBIx::Class',
                    user_model  => 'ManocDB::User',
                    role_column => 'roles',
                }
            },
        },
    },

    #remove stale sessions from db
    'Plugin::Session' => {
        expires           => 28800,
        dbi_dbh           => 'ManocDB',
        dbi_table         => 'sessions',
        dbi_id_field      => 'id',
        dbi_data_field    => 'session_data',
        dbi_expires_field => 'expires',
    }
);

sub load_plugins {
    my $self    = shift;
    my $plugins = __PACKAGE__->config->{LoadPlugin};
    my ( $class, $file );

    foreach my $it ( keys %{$plugins} ) {
        my $plugin = ucfirst($it);
        # hack stolen from catalyst:
        # don't overwrite $@ if the load did not generate an error
        my $error;
        {
            local $@;
            $class = "App::Manoc::Plugin::" . $plugin . "::Init";
            $file  = $class . '.pm';
            $file =~ s{::}{/}g;
            eval { CORE::require($file) };
            $error = $@;
        }
        die $error if $error;

        $class->load( __PACKAGE__->config->{LoadPlugin}->{$it} );
    }
}

sub _add_plugin {
    my ( $name, $opt ) = @_;
    $name or die "missing plugin name";
    $opt ||= 1;
    my $plugin = __PACKAGE__->plugin_registry;
    $plugin->{$name} = $opt;
    __PACKAGE__->plugin_registry($plugin);
}

########################################################################

########################################################################

after setup_finalize => sub {
    #Load Search Plugins
    __PACKAGE__->load_plugins;

};

# Start the application
__PACKAGE__->setup();

no Moose;

__PACKAGE__->meta->make_immutable( replace_constructor => 1 );

1;

=head1 SYNOPSIS

    script/manoc_server.pl

=head1 DESCRIPTION

Manoc is a web-based network monitoring/reporting platform designed for moderate to large networks.

Manoc can collect:

=over 4

=item Ports status and mac-address associations network devices via SNMP

=item Ethernet/IP address pairings via a sniffer agenta

=item DHCP leases/reservations using a lightweight agent for ISC DHCPD
based servers

=item users and computer logon in a Windows AD environment, using an
agent for syslog-ng to trap snare generated syslog messages

=back

Data is stored using a SQL database like Postgres or MySQL using DBIx::Class .

=begin markdown

[![Build Status](https://travis-ci.org/ManocLabs/manoc.svg?branch=master)](https://travis-ci.org/ManocLabs/manoc)

=end markdown


=head1 SEE ALSO

L<Catalyst> L<SNMP::Info> L<Moose>

=cut

=cut
