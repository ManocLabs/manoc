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

=action  vid

View Vlan by vid

=cut

sub vid : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $vid ) = @_;

    if ( $self->enable_permission_check && $self->view_object_perm ) {
        $c->require_permission( $c->stash->{resultset}, $self->view_object_perm );
    }

    $c->stash(
        vid => $vid,
        object_list => $c->stash->{resultset}->search( { vid => $vid } )
    );

}

=action list

Display a list of items.

=cut

sub list : Chained('base') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    if ( $self->enable_permission_check && $self->view_object_perm ) {
        $c->require_permission( $c->stash->{resultset}, $self->view_object_perm );
    }

    my $segment_list = [
        $c->model('ManocDB::LanSegment')->search(
            {},
            {
                order_by => ['me.name'],
            }
        )->all()
    ];

    my $qp            = $c->req->query_parameters;
    my $segment_param = $qp->{lansegment};
    $c->debug and $c->log->debug("looking for segment=$segment_param");

    my $segment = $c->model('ManocDB::LanSegment')->find( { id => $segment_param } );
    $c->debug and $c->log->debug( $segment ? "segment found" : "segment not foud" );

    $segment ||= $c->model('ManocDB::LanSegment')->search()->first;

    $c->stash(
        segment_list => $segment_list,
        cur_segment  => $segment,
    );

}

=action create

=cut

before 'create' => sub {
    my ( $self, $c ) = @_;

    my $range_id = $c->req->query_parameters->{'range'};

    my $range = $c->model('ManocDB::VlanRange')->find( { id => $range_id } );

    if ( !$range ) {
        $c->response->redirect( $c->uri_for_action('vlan/list') );
        $c->detach();
    }

    $c->stash( form_parameters => { vlan_range => $range_id } );
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

    return $c->uri_for_action("vlan/list");
}

__PACKAGE__->meta->make_immutable;

1;
