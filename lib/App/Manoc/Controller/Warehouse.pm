package App::Manoc::Controller::Warehouse;
#ABSTRACT:T Warehouse controller

use Moose;
##VERSION

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }
with
    'App::Manoc::ControllerRole::CommonCRUD',
    'App::Manoc::ControllerRole::JSONView';

use App::Manoc::Form::Warehouse;

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'warehouse',
        }
    },
    class      => 'ManocDB::Warehouse',
    form_class => 'App::Manoc::Form::Warehouse',

    edit_page_title   => 'Edit warehouse',
    create_page_title => 'New warehouse',

    enable_permission_check => 1,
    view_object_perm        => undef,
    json_columns            => [ 'id', 'name' ],
    object_list_options     => {
        prefetch => 'building',
        join     => 'building',
        order_by => 'me.name',
    }
);

=action create

Override default to pass building parameter to form.

=cut

before 'create' => sub {
    my ( $self, $c ) = @_;

    my $building_id = $c->req->query_parameters->{'building'};
    $c->stash( form_defaults => { building => $building_id } );
};

=method delete_object

Override default to check for assets before deleting.

=cut

sub delete_object {
    my ( $self, $c ) = @_;

    my $warehouse = $c->stash->{'object'};

    if ( $warehouse->hwassets->count ) {
        $c->flash( error_msg => "Warehouse is not empty. Cannot be deleted." );
        return;
    }

    return $warehouse->delete;
}

__PACKAGE__->meta->make_immutable;

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
