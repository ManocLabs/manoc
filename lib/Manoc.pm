package Manoc;

use Moose;
use namespace::autoclean;

require 5.10.1;
use version 0.77; # even for Perl v.5.10.0
our $VERSION = qv('2.009_001');


use Catalyst::Runtime 5.90;

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
    Authorization::Roles
    Authorization::ACL
    Session
    Session::Store::DBI
    Session::State::Cookie
    +Manoc::CatalystPlugin::RequestToken
    StackTrace
    /;

extends 'Catalyst';

with 'Manoc::Logger::CatalystRole';
with 'Catalyst::ClassData';

__PACKAGE__->mk_classdata("plugin_registry");
__PACKAGE__->plugin_registry({});

# Configure the application.
#
# Note that settings in manoc.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name         => 'Manoc',

    # Views setup
    default_view => 'TT',

    use_request_uri_for_path => 1,

    'Model::ManocDB' => {
	connect_info => [
	    $ENV{MANOC_DB_DSN} || 'dbi:SQLite:manoc.db',
	    $ENV{MANOC_DB_USERNAME},
	    $ENV{MANOC_DB_PASSWORD},
	    { AutoCommit => 1 },
            { quote_names => 1 },
	],
    },

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,

    'Plugin::Authentication' => {
        default_realm => 'userdb',
        realms        => {
            userdb => {
                credential => {
                    class              => 'Password',
                    password_field     => 'password',
                    password_type      => 'self_check',
                },
                store => {
                    class         => 'DBIx::Class',
                    user_model    => 'ManocDB::User',
                    role_relation => 'roles',
                    role_field    => 'role',
                },
            },
            agent => {
                credential => {
                    class              => 'HTTP',
                    type               => 'basic',
                    password_field     => 'password',
		    password_type      => 'self_check',
                },
                store => {
                    class         => 'DBIx::Class',
                    user_model    => 'ManocDB::User',
                    role_relation => 'roles',
                    role_field    => 'role',
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
  my ($class,$file);

  foreach my $it (keys %{$plugins}){
    my $plugin = ucfirst($it);
    # hack stolen from catalyst:
    # don't overwrite $@ if the load did not generate an error
    my $error;
    {
      local $@;
      $class = "Manoc::Plugin::".$plugin."::Init";
      $file = $class . '.pm';
      $file =~ s{::}{/}g;
      eval { CORE::require($file) };
      $error = $@;
    }
    die $error if $error;
    
    $class->load(__PACKAGE__->config->{LoadPlugin}->{$it});
  }
}

sub _add_plugin {
     my ($name,$opt) = @_;
     $name or die "missing plugin name";
     $opt ||= 1;
     my $plugin = __PACKAGE__->plugin_registry; 
     $plugin->{$name} = $opt;
     __PACKAGE__->plugin_registry($plugin);
}


########################################################################

########################################################################

after setup_finalize => sub {

    #default admin ACL for full CRUD resources
    my @CRUD        = qw/create edit delete/;
    my @controllers = qw/device building rack ipnetwork vlan vlanrange mngurlformat user/;

    foreach my $ctrl (@controllers) {
        foreach (@CRUD) {
            __PACKAGE__->deny_access_unless( "$ctrl/$_", [qw/admin/] );
        }
    }

    #Additional acl for admin privileges
    my @add_acl =
        qw{ 
        device/uplinks device/refresh 
        vlanrange/split vlanrange/merge 
        interface/edit_notes interface/delete_notes 
        ip/edit ip/delete
    };
    foreach my $acl (@add_acl) {
        __PACKAGE__->deny_access_unless( $acl, [qw/admin/] );
    }

    #Load Search Plugins
    __PACKAGE__->load_plugins;

};

# Start the application
__PACKAGE__->setup();


=head1 NAME

Manoc - Network monitoring application

=head1 SYNOPSIS

    script/manoc_server.pl

=head1 DESCRIPTION

Manoc configuration class

=head1 SEE ALSO

L<Manoc::Controller::Root>, L<Catalyst>

=head1 AUTHORS

Gabriele Mambrini

Enrico Liguori

=head1 LICENSE

Copyright 2011-2014 by the AUTHORS

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

no Moose;

__PACKAGE__->meta->make_immutable(replace_constructor => 1);

1;
