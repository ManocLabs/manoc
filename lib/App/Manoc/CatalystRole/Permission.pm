package App::Manoc::CatalystRole::Permission;
#ABSTRACT: Catalyst plugin for Manoc permissions

=head1 DESCRIPTION

This Role is used as a Catalyst plugin to implement Manoc authorization
control.

Permissions are mapped to roles via the C<%DEFAULT_ROLES> hash, merged with
C<App::Manoc::Permission> configuration.

=head1 SYNOPSIS

  sub view : Chained('object') : PathPart('view') : Args(0) {
      my ( $self, $c ) = @_;

      # check view permission or display permission denied page
      $c->require_permission( $object, 'view' );
  }

  sub view : Chained('object') : PathPart('create') : Args(0) {
      my ( $self, $c ) = @_;

      # check view permission or display permission denied page
      $c->require_permission( 'foo.create' );
  }

=cut

use Moose::Role;

##VERSION

use namespace::autoclean;

use Catalyst::Exception ();
use Catalyst::Utils;
use Scalar::Util;

our %DEFAULT_ROLES = (
    'DHCPAgent'      => [ 'api:dhcp.*', ],
    'WinlogonAgent'  => [ 'api:winlogon.*', ],
    'AssetManager'   => [ 'device.*', 'building.*', 'rack.*', 'uplink.*', ],
    'NetworkManager' => [
        'ifnotes.*', 'ip.*',   'ipblock.*', 'ipnetwork.*',
        'uplink.*',  'vlan.*', 'vlanrange.*',
    ],
);

after setup_finalize => sub {
    my $app          = shift;
    my $cfg          = $app->_permission_plugin_config;
    my $roles_config = $cfg->{'roles'};

    my $role_map = Catalyst::Utils::merge_hashes( \%DEFAULT_ROLES, $roles_config );

    $app->_permission_roles_map($role_map);
};

sub _permission_plugin_config {
    my $c = shift;
    return $c->config->{'App::Manoc::Permission'} ||= {};
}

sub _permission_roles_map {
    my $c     = shift;
    my $value = shift;

    if ($value) {
        $c->_permission_plugin_config->{_roles_map} = $value;
    }
    return $c->_permission_plugin_config->{_roles_map} ||= {};
}

sub _check_permission_cache {
    my ( $c, $user, $permission ) = @_;

    my $roles2perm = $c->_permission_roles_map;
    my $cache      = $c->session->{permission_cache};

    if ( !defined($cache) ) {
        $cache = {};

        foreach my $role ( $user->roles ) {
            $c->log->debug("User role: $role") if $c->debug;
            foreach my $p ( @{ $roles2perm->{$role} } ) {
                $c->log->debug("User $p granted by $role") if $c->debug;
                $cache->{$p} = 1;
            }
        }
        $c->session->{permission_cache} = $cache;
    }
    return $cache->{$permission};
}

=method check_permission ( $c, $object, $operation, [ $user ] )

Check if $user is authorized to perform $operation on $object.
If $user is not specified used the currently logged user.

Instead of the $object, $operation pair permission can also be expressed
as a string  <class>.<operation>, e.g. C<"device.create">.

If object has a specific check_permission method use
C| $object->check_permission( $user, $operation ) |
otherwise use the default role to group map.


If user is superadmin always return true.

=cut

sub check_permission {
    my ( $c, $object, $operation, $maybe_user ) = @_;

    my $user;
    if ( Scalar::Util::blessed($maybe_user) &&
        $maybe_user->isa("Catalyst::Authentication::User") )
    {
        $user = $maybe_user;
    }
    $user ||= $c->user;

    # check user object
    unless ($user) {
        Catalyst::Exception->throw("No logged in user, and none supplied as argument");
    }
    Catalyst::Exception->throw("User does not support roles")
        unless $user->supports(qw/roles/);

    if ( $user->superadmin ) {
        $c->log->debug("Skipping permission check for superadmin") if $c->debug;
        return 1;
    }

    # check if object is a ref or a class name
    my $class_name;
    if ( Scalar::Util::blessed($object) ) {

        # check if object has a specific check_permission method
        if ( $object->can('check_permission') ) {
            return $object->check_permission( $user, $operation );
        }

        if ( $object->isa("DBIx::Class::ResultSource") ) {
            $class_name = $object->source_name;
        }
        elsif ( $object->isa("DBIx::Class::ResultSet") ||
            $object->isa("DBIx::Class::Row") )
        {
            $class_name = $object->result_source->source_name;
        }
        else {
            Catalyst::Exception->throw("Cannot guess object source_name");
        }

    }
    else {
        $class_name = $object;
    }
    # construct permission symbolic name
    my $permission = lc($class_name);
    my $star_permission;
    if ($operation) {
        $permission .= '.' . lc($operation);
        $star_permission = "$permission.*";
    }
    elsif ( $permission =~ /([^\.]+)\.([^\.]+)/o ) {
        $star_permission = "$1.*";
    }

    $c->log->debug("Checking permission $permission") if $c->debug;
    if ( $c->_check_permission_cache( $user, $permission ) ) {
        $c->log->debug("Permission $permission granted") if $c->debug;
        return 1;
    }

    if ( $c->_check_permission_cache( $user, $star_permission ) ) {
        $c->log->debug("Permission $permission granted by $star_permission") if $c->debug;
        return 1;
    }

    $c->log->debug("Permission $permission denied") if $c->debug;
    return 0;
}

=method require_permission

check_permission or detach to access denied page.

=cut

sub require_permission {
    my $c = shift;

    $c->check_permission(@_) or
        $c->detach('/access_denied');
}

no Moose::Role;
1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
