package App::Manoc::Controller::Vlan;
#ABSTRACT: Vlan controller

use Moose;

##VERSION

use namespace::autoclean;
use App::Manoc::Form::Vlan;

BEGIN { extends 'Catalyst::Controller'; }
with
    'App::Manoc::ControllerRole::CommonCRUD' => { -excludes => 'list' },
    'App::Manoc::ControllerRole::JSONView';

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'vlan',
        }
    },
    class                   => 'ManocDB::Vlan',
    form_class              => 'App::Manoc::Form::Vlan',
    json_columns            => [ 'id', 'name', 'description' ],
    enable_permission_check => 1,
    view_object_perm        => undef,
    object_list_options     => {
        prefetch => 'vlan_range',
    }
);

=action index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->res->redirect( $c->uri_for_action('vlanrange/list') );
}

=action create

=cut

before 'create' => sub {
    my ( $self, $c ) = @_;

    my $range_id = $c->req->query_parameters->{'range'};
    $c->stash( form_defaults => { vlan_range => $range_id } );
};

=method object_delete

=cut

sub object_delete {
    my ( $self, $c ) = @_;
    my $vlan = $c->stash->{'object'};

    if ( $vlan->ip_ranges->count ) {
        $c->flash( error_msg => 'There are subnets in this vlan' );
        return;
    }

    $vlan->delete;
}

=method get_form_success_url

=cut

sub get_form_success_url {
    my ( $self, $c ) = @_;

    return $c->uri_for_action("vlanrange/list");
}

__PACKAGE__->meta->make_immutable;

1;
