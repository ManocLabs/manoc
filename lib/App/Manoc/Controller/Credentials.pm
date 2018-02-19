package App::Manoc::Controller::Credentials;
#ABSTRACT: Building Controller

use Moose;

##VERSION

use namespace::autoclean;

use App::Manoc::Form::Credentials;

BEGIN { extends 'Catalyst::Controller'; }
with
    "App::Manoc::ControllerRole::CommonCRUD" => { -excludes => 'delete_object', },
    "App::Manoc::ControllerRole::JSONView";

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'credentials',
        }
    },
    class                   => 'ManocDB::Credentials',
    form_class              => 'App::Manoc::Form::Credentials',
    enable_permission_check => 1,
    view_object_perm        => undef,
);

=method delete_object

Override default implementation to warn when building has associated racks or
warehouses.

=cut

sub delete_object {
    my ( $self, $c ) = @_;
    my $credentials = $c->stash->{'object'};

    if ( $credentials->device_nw_info->count || $credentials->server_nw_info->count ) {
        $c->flash( error_msg =>
                'These credental set has associated configurations and cannot be deleted.' );
        return;
    }

    return $credentials->delete;
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
