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
use Set::Object;
use Scalar::Util;

use namespace::clean -except => 'meta';

__PACKAGE__->mk_classdata( "_permission_to_role" );


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
    ],
    'NetworkManager' => [
        'vlan.*',
        'vlanrange.*',
        'ipnetwork.*',
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
    my $permission_to_role = {};

    my $cfg = $app->_permission_plugin_config;
    my $roles_config = $cfg->{'roles'};

    my $roles = Catalyst::Utils::merge_hashes(\%DEFAULT_ROLES, $roles_config );

    while ( my ($role, $perms) = each(%$roles) ) {
        foreach my $perm (@$perms) {
            push @{$permission_to_role->{$perm}}, $role;
        }
    }

    $app->_permission_to_role( $permission_to_role );
}

sub check_permission {
    my ($c, $object, $operation, $maybe_user) = @_;

    my $user;
    if ( Scalar::Util::blessed( $maybe_user )
           && $maybe_user->isa("Catalyst::Authentication::User") )
    {
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
        } else {
            Catalyst::Exception->throw("Object isn't a resultset");
        }

    } else {
        $class_name = $object;
    }

    my $permission = lc($class_name);
    my $star_permission;

    if ($operation) {
        $star_permission = "$permission.*";
        $permission .= '.' . lc($operation);
    }

    my $need = Set::Object->new( $c->get_roles_for_perm($permission) );
    $star_permission and
        $need->insert( $c->get_roles_for_perm($star_permission));

    my $have = Set::Object->new( $user->roles );

    if ( $have->intersection($need)->size > 0 ) {
        $c->log->debug("Permission $permission granted") if $c->debug;
        return 1;
    }

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
