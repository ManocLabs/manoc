package Manoc;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

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
    Scheduler
    Session
    Session::Store::DBI
    Session::State::Cookie
    StackTrace
    /;

extends 'Catalyst';

with 'Manoc::Search';
with 'Manoc::Logger::CatalystRole';

our $VERSION = '1.98';
$VERSION = eval $VERSION;

use Data::Dumper;

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
    default_view => 'TT',
    use_request_uri_for_path => 1,

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    'Plugin::Authentication'                    => {
        default_realm => 'progressive',
        realms        => {
            progressive => {
                class  => 'Progressive',
                realms => [ 'normal', 'agents' ],
            },
            normal => {
                credential => {
                    class              => 'Password',
                    password_field     => 'password',
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
            agents => {
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
        },
    },

    'Plugin::Session' => {
        expires           => 3600,
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
        qw{ device/change_ip device/uplinks vlanrange/split vlanrange/merge iprange/split
        iprange/merge user/switch_status user/set_roles vlan/merge_name
        interface/edit_notes interface/delete_notes ip/edit_notes ip/delete_notes
    };
    foreach my $acl (@add_acl) {
        __PACKAGE__->deny_access_unless( $acl, [qw/admin/] );
    }

    #ACL to protect WApi with HTTP Authentication
    __PACKAGE__->deny_access_unless( "/wapi", sub { $_[0]->authenticate( {}, 'agents' ) } );

};

# Start the application
__PACKAGE__->setup();

__PACKAGE__->schedule(
    at    => '@hourly',
    event => '/cron/remove_sessions'
);

=head1 NAME

Manoc - Network monitoring application

=head1 SYNOPSIS

    script/manoc_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<Manoc::Controller::Root>, L<Catalyst>

=head1 AUTHOR

See README

=head1 LICENSE

Copyright 2011 by the Manoc Team

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
