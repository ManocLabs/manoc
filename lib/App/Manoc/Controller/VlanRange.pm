package App::Manoc::Controller::VlanRange;
#ABSTRACT: VlanRange controller
use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }
with
    "App::Manoc::ControllerRole::CommonCRUD" => { -excludes => [ 'list', 'view' ] },
    "App::Manoc::ControllerRole::JSONView";

use App::Manoc::Form::VlanRange;
use App::Manoc::Form::VlanRange::Merge;
use App::Manoc::Form::VlanRange::Split;

BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'vlanrange',
        }
    },
    class                   => 'ManocDB::VlanRange',
    form_class              => 'App::Manoc::Form::VlanRange',
    enable_permission_check => 1,
    view_object_perm        => undef,
    json_columns            => [qw(id lansegment name description)],
    object_list             => {
        order_by => [ 'start', 'vlans.id' ],
        prefetch => 'vlans',
        join     => 'vlans',
    }
);

=action split

=cut

sub split : Chained('object') : PathPart('split') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{object}, 'edit' );

    my $form = App::Manoc::Form::VlanRange::Split->new( { ctx => $c } );

    $c->stash(
        form   => $form,
        action => $c->uri_for( $c->action, $c->req->captures ),
    );
    return unless $form->process(
        item   => $c->stash->{object},
        params => $c->req->parameters,
    );

    $c->response->redirect( $c->uri_for_action('vlan/list') );
    $c->detach();
}

=action merge

=cut

sub merge : Chained('object') : PathPart('merge') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{object}, 'edit' );

    my $form = App::Manoc::Form::VlanRange::Merge->new( { ctx => $c } );

    $c->stash(
        form   => $form,
        action => $c->uri_for( $c->action, $c->req->captures ),
    );
    return unless $form->process(
        item   => $c->stash->{object},
        params => $c->req->parameters,
    );

    $c->response->redirect( $c->uri_for_action('vlan/list') );
    $c->detach();
}

=head1 METHODS


=head2 create

=cut

before 'create' => sub {
    my ( $self, $c ) = @_;

    my $segment_id = $c->req->query_parameters->{'lansegment'};
    my $segment = $c->model('ManocDB::LanSegment')->find( { id => $segment_id } );

    if ( !$segment ) {
        $c->response->redirect( $c->uri_for_action('vlan/list') );
        $c->detach();
    }

    $c->stash( form_parameters => { lan_segment => $segment } );
};

=cut

=method delete_object

=cut

sub delete_object {

    my ( $self, $c ) = @_;
    my $range = $c->stash->{'object'};
    my $id    = $range->id;
    my $name  = $range->name;

    if ( $range->vlans->count() ) {
        $c->flash( error_msg => "There are vlans in vlan range '$name'. Cannot delete it." );
        return;
    }

    return $range->delete;
}

=method get_form_success_url

=cut

sub get_form_success_url {
    my ( $self, $c ) = @_;

    return $c->uri_for_action("vlan/list");
}

=method get_delete_success_url

=cut

sub get_delete_success_url {
    my ( $self, $c ) = @_;

    return $c->uri_for_action("vlan/list");
}

=method get_delete_failure_url

=cut

sub get_delete_failure_url {
    my ( $self, $c ) = @_;

    return $c->uri_for_action("vlan/list");
}

__PACKAGE__->meta->make_immutable;

1;
