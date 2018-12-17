package App::Manoc::Controller::DeviceIface;
#ABSTRACT: Interface Controller

use Moose;

##VERSION

BEGIN { extends 'Catalyst::Controller'; }

=head1 CONSUMED ROLES

=for :list
* App::Manoc::ControllerRole::CommonCRUD
* App::Manoc::ControllerRole::JSONView

=cut

with
    "App::Manoc::ControllerRole::CommonCRUD" => { -excludes => ["list"] },
    "App::Manoc::ControllerRole::JSONView";

use namespace::autoclean;

__PACKAGE__->config(
    action => {
        setup => {
            PathPart => 'deviceiface',
        }
    },
    class             => 'ManocDB::DeviceIface',
    create_form_class => 'App::Manoc::Form::DeviceIface::Create',
    edit_form_class   => 'App::Manoc::Form::DeviceIface::Edit',

    object_list_options => {
        prefetch => [ 'status', ]
    },
);

use App::Manoc::Form::DeviceIface::Create;
use App::Manoc::Form::DeviceIface::Edit;
use App::Manoc::Form::DeviceIface::Populate;

=method find_device

=cut

sub find_device {
    my ( $self, $c ) = @_;

    my $device = $c->stash->{device};
    if ( !$device ) {
        my $device_id = $c->stash->{device_id} // $c->req->query_parameters->{'device'};
        $device = $c->model('ManocDB::Device')->find($device_id);
        $c->stash->{device} = $device;
    }
    $device or return;

    $c->stash( device_id => $device->id );
    return $device;
}

=method create

=cut

before 'create' => sub {
    my ( $self, $c ) = @_;
    my $device = $self->find_device($c);
    $c->stash( form_parameters => { device_id => $device->id } );
    $c->stash( title => 'New interface' );
};

=action populate

For interfaces batch creation

=cut

sub populate : Chained('base') : PathPart('populate') : Args(0) {
    my ( $self, $c ) = @_;

    my $device = $self->find_device($c);
    $c->require_permission( $device, 'edit' );

    my $form = App::Manoc::Form::DeviceIface::Populate->new( { device => $device, ctx => $c } );

    $c->stash(
        form   => $form,
        action => $c->uri_for( $c->action, $c->req->captures ),
        title  => 'Create interface range',
        form_require_post         => 1,    # posted => ($c->req->method eq 'POST'),
        object_form_ajax_add_html => 1,    # enable manoc ajax forms
    );

    $c->forward('object_form');

    if ( $c->stash->{is_xhr} ) {
        $c->forward('object_form_ajax_response');
        return;
    }

    $c->stash->{form}->is_valid and
        $c->res->redirect( $c->uri_for_action( 'device/view', [ $device->id ] ) );
}

=action list_uncabled_js

=cut

sub list_uncabled_js : Chained('base') : PathPart('uncabled') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{resultset}, 'list' );

    my $device_id = $c->req->query_parameters->{'device'};
    my $q         = $c->req->query_parameters->{'q'};

    my $filter;
    $q and $filter->{name} = { -like => "$q%" };
    $device_id and $filter->{device_id} = $device_id;

    my @ifaces =
        $c->model('ManocDB::DeviceIface')->search_uncabled()->search( $filter, {} )->all();

    my @data = map +{
        device_id => $_->device_id,
        id        => $_->id,
        name      => $_->name
    }, @ifaces;

    $c->stash( json_data => \@data );
    $c->forward('View::JSON');
}

=method view

=cut

sub view : Chained('object') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    my $object = $c->stash->{'object'};

    # handy for templates
    $c->stash( device => $object->device );

    #MAT related results
    my @mat_rs = $c->model('ManocDB::Mat')->search(
        {
            device_id => $object->device_id,
            interface => $object->name,
        },
        { order_by => { -desc => [ 'lastseen', 'firstseen' ] } }
    );
    my @mat_results = map +{
        macaddr   => $_->macaddr,
        vlan      => $_->vlan,
        firstseen => $_->firstseen,
        lastseen  => $_->lastseen
    }, @mat_rs;

    $c->stash( mat_history => \@mat_results );
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
