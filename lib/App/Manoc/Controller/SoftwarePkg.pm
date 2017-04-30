package App::Manoc::Controller::SoftwarePkg;
#ABSTRACT: SoftwarePkg controller

use Moose;

##VERSION

use namespace::autoclean;

use App::Manoc::Form::Building;

BEGIN { extends 'Catalyst::Controller'; }

with
    'App::Manoc::ControllerRole::ResultSet',
    'App::Manoc::ControllerRole::Object',
    'App::Manoc::ControllerRole::JQDatatable';

=head1 METHODS

=cut

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'softwarepkg',
        }
    },
    class                   => 'ManocDB::SoftwarePkg',
    enable_permission_check => 1,
    view_object_perm        => undef,

    datatable_columns        => [ 'name', 'n_servers' ],
    datatable_row_callback   => 'datatable_row',
    datatable_search_columns => ['name'],
    datatable_search_options => {
        '+select' => [
            {
                count => 'server_swpkg.server_id',
                -as   => 'n_servers',
            }
        ],
        group_by => ['id'],
        join     => 'server_swpkg',
    },
    # datatable_search_callback => 'datatable_search_cb',
);

sub datatable_row {
    my ( $self, $c, $row ) = @_;

    my $action = 'softwarepkg/view';

    return {
        name      => $row->name,
        n_servers => $row->get_column('n_servers'),
        link      => $c->uri_for_action( $action, [ $row->id ] ),
    };
}

=head2 view

Display a single items.

=cut

sub view : Chained('object') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{resultset}, 'view' );

    my $object = $c->stash->{object};

}

=head2 list

Display a list of items. Chained to base since the table is AJAX based

=cut

sub list : Chained('base') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{resultset}, 'list' );
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
