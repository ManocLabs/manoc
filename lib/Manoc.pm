package Manoc;
use Moose;
use namespace::autoclean;

require 5.10.1;
use version 0.77; # even for Perl v.5.10.0
our $VERSION = qv('2.002_001');


use Catalyst::Runtime 5.90;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
    Authentication
    Authorization::Roles
    Authorization::ACL
    Scheduler
    Session
    Session::Store::DBI
    Session::State::Cookie
    StackTrace
    /;

extends 'Catalyst';

with 'Manoc::Search';
with 'Manoc::Logger::CatalystRole';
with 'Catalyst::ClassData';

use Data::Dumper;
use Manoc::Search::QueryType;

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
    default_view => 'WebPage',
 
    use_request_uri_for_path => 1,

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,

    'Plugin::Authentication'                    => {
        default_realm => 'progressive_ui',
        realms        => {
            progressive_ui => {
                class  => 'Progressive',
                realms => [ 'normal',
			    #'ldap',
			],
            },
	   
            normal => {
                credential => {
                    class              => 'Password',
                    password_field     => 'password',
                    username_field     => 'login',
                    password_type      => 'hashed',
                    password_hash_type => 'MD5'
                },
                store => {
                    class         => 'DBIx::Class',
                    user_model    => 'ManocDB::User',
                    role_relation => 'roles',
                    role_field    => 'role',
                }
            },
            agent => {
                credential => {
                    class              => 'HTTP',
                    type               => 'basic',      # 'digest' or 'basic'
                    password_field     => 'password',
                    username_field     => 'login',
                    password_type      => 'hashed',
                    password_hash_type => 'MD5',
                },
                store => {
                    class         => 'DBIx::Class',
                    user_model    => 'ManocDB::User',
                    role_relation => 'roles',
                    role_field    => 'role',
                }
            },
#            ldap => {
#                credential => {
#                  class => "Password",
#                  username_field => "username",
#                  password_field => "password",
#                  password_type  => "self_check",
#                },
#                store => {
#                  class               => "LDAP",
#                  ldap_server         => "",
#                  ldap_server_options => { timeout => 100 , onerror => "warn"},
#                  role_basedn         => "ou=ManocRoles,dc=bla,dc=bla,dc=bla", #This should be the basedn where the LDAP Objects representing your roles are.
#                  role_field          => "cn",
#                  role_filter         => "",
#                  role_scope          => "one",
#                  role_search_options => { deref => "always" },
#                  role_value          => "cn",
#                  role_search_as_user => 0, #role disabled
#                  start_tls           => 0, #disabled
#                  start_tls_options   => { verify => "none" },
#                  entry_class         => "Net::LDAP::Entry",
#                  use_roles           => 1,
#                  user_basedn         => "ou=People,dc=bla,dc=bla,dc=bla",
#                  user_field          => "uid",
#                  user_filter         => "(&(objectClass=posixAccount)(uid=%s))",
#                  user_scope          => "sub", # 
#                  user_search_options => { deref => "always" },
#                  user_results_filter => sub { return shift->pop_entry },
#                },
#              },
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

########################################################################

sub check_backref {
    my $c       = shift;
    my $backref = $c->flash->{'backref'};
    return $backref;
}

sub set_backref : Private {
    my $c       = shift;
    my $backref = $c->req->param('backref');
    if ($backref) {
        $c->flash( backref => $backref );
        delete $c->request->parameters->{'backref'};
    }
}

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
    my @controllers = qw/device building rack iprange vlan vlanrange mngurlformat user/;

    foreach my $ctrl (@controllers) {
        foreach (@CRUD) {
            __PACKAGE__->deny_access_unless( "$ctrl/$_", [qw/admin/] );
        }
    }

    #Additional acl for admin privileges
    my @add_acl =
        qw{ device/change_ip device/uplinks device/refresh vlanrange/split vlanrange/merge iprange/split
        iprange/merge user/switch_status user/set_roles vlan/merge_name
        interface/edit_notes interface/delete_notes ip/edit ip/delete
    };
    foreach my $acl (@add_acl) {
        __PACKAGE__->deny_access_unless( $acl, [qw/admin/] );
    }

    #ACL to protect WApi with HTTP Authentication
    __PACKAGE__->deny_access_unless( "/wapi", sub { $_[0]->authenticate( {}, 'agent' ) } );

    #Load Search Plugins    

    __PACKAGE__->load_plugins;

};

# Start the application
__PACKAGE__->setup();

__PACKAGE__->schedule(
    at    => '@daily',
    event => '/cron/remove_sessions'
);

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
