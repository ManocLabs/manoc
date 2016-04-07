# Copyright 2016 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::CatalystPlugin::Permission;

use Moose;
with 'Catalyst::ClassData';

use MRO::Compat;

use Catalyst::Exception ();
use Carp;
use Catalyst::Utils;
use Scalar::Util;

use namespace::clean -except => 'meta';

__PACKAGE__->mk_classdata( "_permission_roles_map" );



our %DEFAULT_ROLES = (
    'DHCPAgent' => [
        'api:dhcp.*',
    ],
    'WinlogonAgent' => [
        'api:winlogon.*',
    ],
    'AssetManager' => [
        'device.*',
        'building.*',
        'rack.*',
        'uplink.*',
    ],
    'NetworkManager' => [
        'ifnotes.*',
        'ip.*',
        'ipblock.*',
        'ipnetwork.*',
        'uplink.*',
        'vlan.*',
        'vlanrange.*',
    ],
);

sub _permission_plugin_config {
    my $c = shift;
    return $c->config->{'Manoc::Permission'} ||= {};
}


sub setup {
    my $app = shift;

    $app->maybe::next::method(@_);
    $app->setup_permissions;

    return $app;
}

sub setup_permissions {
    my $app = shift;
    my $cfg = $app->_permission_plugin_config;
    my $roles_config = $cfg->{'roles'};

    my $roles = Catalyst::Utils::merge_hashes(\%DEFAULT_ROLES, $roles_config );
    $app->_permission_roles_map($roles);
}

sub _get_roles_for_perm {
    return shift->_permission_to_role->{shift};
}

sub _check_permission_cache {
    my ($c, $user, $permission) = @_;

    my $roles2perm = $c->_permission_roles_map;
    my $cache = $c->session->{permission_cache};

    if (!defined($cache)) {
        $cache = {};

        foreach my $role ( $user->roles ) {
            $c->log->debug( "User role: $role") if $c->debug;
            foreach my $p (@{$roles2perm->{$role}} ) {
                $c->log->debug( "User $p granted by $role") if $c->debug;
                $cache->{$p} = 1;
            }
        }
        $c->session->{permission_cache} = $cache;
    }
    return $cache->{$permission};
}


sub require_permission {
    my $c = shift;

    $c->check_permission(@_) or
        $c->detach('/access_denied');
}

sub check_permission {
    my ($c, $object, $operation, $maybe_user) = @_;

    my $user;
    if ( Scalar::Util::blessed( $maybe_user )
           && $maybe_user->isa("Catalyst::Authentication::User") )  {
           $user = $maybe_user;
    }
    $user ||= $c->user;

    # check user object
    unless ( $user ) {
        Catalyst::Exception->throw(
            "No logged in user, and none supplied as argument");
    }
    Catalyst::Exception->throw("User does not support roles")
         unless $user->supports(qw/roles/);

    if ($user->superadmin) {
        $c->log->debug("Skipping permission check for superadmin") if $c->debug;
        return 1;
    }

    # check if object is a ref or a class name
    my $class_name;
    if ( Scalar::Util::blessed($object) ) {

        # check if object has a specific check_permission method
        if ($object->can('check_permission')) {
            return $object->check_permission($user, $operation);
        }

        if ($object->isa("DBIx::Class::ResultSource")) {
            $class_name = $object->source_name;
        } elsif ($object->isa("DBIx::Class::ResultSet") ||
                $object->isa("DBIx::Class::Row")) {
            $class_name = $object->result_source->source_name;
        } else {
            Catalyst::Exception->throw("Cannot guess object source_name");
        }

    } else {
        $class_name = $object;
    }
    # construct permission symbolic name
    my $permission = lc($class_name);
    my $star_permission;
    if ($operation) {
        $permission .= '.' . lc($operation);
        $star_permission = "$permission.*";
    } elsif ($permission =~ /([^\.]+)\.([^\.]+)/o) {
        $star_permission = "$1.*";
    }

    $c->log->debug("Checking permission $permission") if $c->debug;
    if ($c->_check_permission_cache($user, $permission)) {
        $c->log->debug("Permission $permission granted") if $c->debug;
        return 1;
    }

    if ($c->_check_permission_cache($user, $star_permission)) {
        $c->log->debug("Permission $permission granted by $star_permission") if $c->debug;
        return 1;
    }

    $c->log->debug("Permission $permission denied") if $c->debug;
    return 0;
}


no Moose;
1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
