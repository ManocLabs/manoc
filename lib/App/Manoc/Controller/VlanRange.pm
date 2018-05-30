package App::Manoc::Controller::VlanRange;
#ABSTRACT: VlanRange controller
use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }
with "App::Manoc::ControllerRole::CommonCRUD";

use App::Manoc::Form::VlanRange;

BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'vlanrange',
        }
    },
    class        => 'ManocDB::VlanRange',
    form_class   => 'App::Manoc::Form::VlanRange',
    json_columns => [qw(id lansegment name description)],
    object_list  => {
        order_by => [ 'lan_segment_id', 'start' ],
    }
);

=head1 METHODS


=head2 create

=cut

before 'create' => sub {
    my ( $self, $c ) = @_;

    my $segment_id = $c->req->query_parameters->{'lansegment'};
    my $segment = $c->model('ManocDB::LanSegment')->find( { id => $segment_id } );
    $c->stash( form_defaults => { lan_segment => $segment } );
};

=action list

Redirect to vlan list

=cut

sub list : Chained('object_list') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    $c->response->redirect( $c->uri_for_action('vlan/list') );
}

=action view

Redirect to edit

=cut

sub view : Chained('object') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};
    $c->response->redirect( $c->uri_for_action( 'vlanrange/edit', [ $object->id ] ) );
}

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
