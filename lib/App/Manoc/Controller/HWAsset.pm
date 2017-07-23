package App::Manoc::Controller::HWAsset;
#ABSTRACT: HWAsset controller
use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

# Not using CommonCRUD
with 'App::Manoc::ControllerRole::ResultSet',
    'App::Manoc::ControllerRole::ObjectForm',
    'App::Manoc::ControllerRole::ObjectList',
    'App::Manoc::ControllerRole::JSONView',
    'App::Manoc::ControllerRole::JQDatatable';

use App::Manoc::DB::Result::HWAsset;
use App::Manoc::Form::HWAsset;

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'hwasset',
        }
    },
    class      => 'ManocDB::HWAsset',
    form_class => 'App::Manoc::Form::HWAsset',

    json_columns =>
        [qw(id serial vendor model inventory rack_id rack_level building_id room label)],

    datatable_row_callback    => 'datatable_row',
    datatable_columns         => [qw(inventory type vendor model serial rack.name)],
    datatable_search_columns  => [qw(serial vendor model inventory)],
    datatable_search_options  => { prefetch => { 'rack' => 'building' } },
    datatable_search_callback => 'datatable_search_cb',

    object_list_filter_columns => [qw( type vendor rack_id building_id )],
);

=action create_device

Create a new device using a form. Chained to base.

=cut

sub create_device : Chained('base') : PathPart('create_device') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{resultset}->new_result( {} );

    ## TODO better permission
    $c->require_permission( $object, 'create' );

    $c->stash(
        object          => $object,
        title           => 'Create device hardware',
        form_class      => 'App::Manoc::Form::HWAsset',
        form_parameters => { type => App::Manoc::DB::Result::HWAsset->TYPE_DEVICE },
    );

    if ( my $nwinfo_id = $c->req->query_parameters->{'nwinfo'} ) {
        my $nwinfo = $c->model('ManocDB::DeviceNWInfo')->find($nwinfo_id);
        if ($nwinfo) {
            my %cols;
            $cols{model}  = $nwinfo->model;
            $cols{vendor} = $nwinfo->vendor;
            $cols{serial} = $nwinfo->serial;
            $c->stash( form_defaults => \%cols );
        }
    }

    $c->detach('form');
}

=action list

Display a list of items. Chained to base since the table is AJAX based

=cut

sub list : Chained('base') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{resultset}, 'list' );
}

=action list_devices

Display a list of items. Chained to base since the table is AJAX based

=cut

sub list_devices : Chained('base') : PathPart('devices') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{resultset}, 'list' );
}

=action view

Display a single item.

=cut

sub view : Chained('object') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};

    if ( $object->type eq App::Manoc::DB::Result::HWAsset->TYPE_SERVER ) {
        $c->res->redirect( $c->uri_for_action( 'serverhw/view', [ $object->serverhw->id ] ) );
        $c->detach();
    }

    $c->require_permission( $object, 'view' );
}

=action edit

Use a form to edit a row. Redirect to specific controllers when the
object is a server or a workstation.

=cut

sub edit : Chained('object') : PathPart('update') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};
    $c->require_permission( $object, 'edit' );

    # redirect serverhw to specific controller
    if ( $object->type eq App::Manoc::DB::Result::HWAsset->TYPE_SERVER ) {
        $c->res->redirect( $c->uri_for_action( 'serverhw/edit', [ $object->serverhw->id ] ) );
        $c->detach();
    }

    # redirect workstation to specific controller
    if ( $object->type eq App::Manoc::DB::Result::HWAsset->TYPE_WORKSTATION ) {
        $c->res->redirect(
            $c->uri_for_action( 'workstationhw/edit', [ $object->workstationhw->id ] ) );
        $c->detach();
    }

    # decommissioned objects cannot be edited
    if ( $object->is_decommissioned ) {
        $c->res->redirect( $c->uri_for_action( 'hwasset/view', [ $object->id ] ) );
        $c->detach();
    }

    $c->stash->{form_parameters}->{type} = $object->type;
    $c->detach('form');
}

=action delete

=cut

sub delete : Chained('object') : PathPart('delete') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};
    $c->require_permission( $object, 'delete' );

    if ( $c->req->method eq 'POST' ) {
        if ( $self->delete_object($c) ) {
            $c->flash( message => $self->object_deleted_message );
            $c->res->redirect( $c->uri_for_action('hwasset/list') );
            $c->detach();
        }
        else {
            $c->res->redirect(
                $c->uri_for_action( 'hwasset/view', [ $c->stash->{object_pk} ] ) );
            $c->detach();
        }
    }

}

=action decommission

=cut

sub decommission : Chained('object') : PathPart('decommission') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};
    $c->require_permission( $object, 'edit' );

    if ( $object->in_use ) {
        $c->response->redirect(
            $c->uri_for_action( 'hwasset/view', [ $c->stash->{object_pk} ] ) );
        $c->detach();
    }

    if ( $c->req->method eq 'POST' ) {
        $object->decommission;
        $object->update();
        $c->flash( message => "Asset decommissioned" );
        $c->response->redirect(
            $c->uri_for_action( 'hwasset/view', [ $c->stash->{object_pk} ] ) );
        $c->detach();
    }

    # show confirm page
    $c->stash(
        title           => 'Decommission hardware',
        confirm_message => 'Decommission hardware ' . $object->label . '?',
        template        => 'generic_confirm.tt',
    );
}

=action restore

=cut

sub restore : Chained('object') : PathPart('restore') : Args(0) {
    my ( $self, $c ) = @_;

    my $hwasset = $c->stash->{object};
    $c->require_permission( $hwasset, 'edit' );

    if ( !$hwasset->is_decommissioned ) {
        $c->response->redirect( $c->uri_for_action( 'hwasset/view', [ $hwasset->id ] ) );
        $c->detach();
    }

    if ( $c->req->method eq 'POST' ) {
        $hwasset->restore;
        $hwasset->update();
        $c->flash( message => "Asset restored" );
        $c->response->redirect( $c->uri_for_action( 'hwasset/view', [ $hwasset->id ] ) );
        $c->detach();
    }

    # show confirm page
    $c->stash(
        title           => 'Restore hardware asset',
        confirm_message => 'Restore ' . $hwasset->label . '?',
        template        => 'generic_confirm.tt',
    );
}

=action vendors_js

Get a list of vendors in JSON, to be used in form autocomplete.

=cut

sub vendors_js : Chained('base') : PathPart('vendors/js') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{resultset}, 'list' );

    my $filter = {};

    my $q = $c->req->query_parameters->{'q'};
    $q and $filter->{vendor} = { -like => "$q%" };

    my @data = $c->stash->{resultset}->search(
        $filter,
        {
            columns  => [qw/vendor/],
            distinct => 1
        }
    )->get_column('vendor')->all();
    $c->log->error("data=@data");
    $c->stash( json_data => \@data );
    $c->forward('View::JSON');
}

=action models_js

Get a list of models optionally filtered by vendor.

=cut

sub models_js : Chained('base') : PathPart('models/js') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{resultset}, 'list' );

    my $filter = {};

    my $vendor = $c->req->query_parameters->{vendor};
    $vendor and $filter->{vendor} = $vendor;

    my $q = $c->req->query_parameters->{'q'};
    $q and $filter->{model} = { -like => "$q%" };

    my @data = $c->stash->{resultset}->search(
        $filter,
        {
            columns  => [qw/model/],
            distinct => 1
        }
    )->get_column('model')->all();

    $c->stash( json_data => \@data );
    $c->forward('View::JSON');
}

=method get_form_process_params

Manage the hide_location query parameter.

=cut

sub get_form_process_params {
    my ( $self, $c, %params ) = @_;

    my $qp = $c->req->query_parameters;
    $qp->{hide_location} and $params{hide_location} = $qp->{hide_location};

    return %params;
}

=method datatable_search_cb

Add support for asset status and warehous.

=cut

sub datatable_search_cb {
    my ( $self, $c, $filter, $attr ) = @_;

    my $extra_filter = {};

    my $status = $c->request->param('search_status');
    if ( defined($status) ) {
        $status eq 'd' and
            $extra_filter->{location} =
            App::Manoc::DB::Result::HWAsset::LOCATION_DECOMMISSIONED;
        $status eq 'w' and
            $extra_filter->{location} = App::Manoc::DB::Result::HWAsset::LOCATION_WAREHOUSE;
        $status eq 'u' and
            $extra_filter->{location} = [
            -and => { '!=' => App::Manoc::DB::Result::HWAsset::LOCATION_DECOMMISSIONED },
            { '!=' => App::Manoc::DB::Result::HWAsset::LOCATION_WAREHOUSE }
            ];
    }

    my $warehouse = $c->request->param('search_warehouse');
    if ( defined($warehouse) ) {
        $extra_filter->{warehouse_id} = $warehouse;
    }

    %$extra_filter and
        $filter = { -and => [ $filter, $extra_filter ] };

    return ( $filter, $attr );
}

=method datatable_row

=cut

sub datatable_row {
    my ( $self, $c, $row ) = @_;

    my $action = 'hwasset/view';

    return {
        inventory => $row->inventory,
        type      => $row->display_type,
        vendor    => $row->vendor,
        model     => $row->model,
        serial    => $row->serial,
        location  => $row->display_location,
        link      => $c->uri_for_action( $action, [ $row->id ] )->as_string,
    };
}

=action datatable_source_devices

Ajax source for datatable listing device assets only.

=cut

sub datatable_source_devices : Chained('base') : PathPart('datatable_source/devices') : Args(0)
{
    my ( $self, $c ) = @_;

    $c->stash->{'datatable_resultset'} = $c->stash->{resultset}->search_rs(
        {
            type => App::Manoc::DB::Result::HWAsset::TYPE_DEVICE,
        }
    );
    $c->forward('/hwasset/datatable_source');
}

=action unused_devices_js

=cut

sub unused_devices_js : Chained('base') : PathPart('js/device/unused') {
    my ( $self, $c ) = @_;

    my $rs = $c->stash->{resultset};
    $c->stash( object_list => [ $rs->unused_devices->all() ] );
    $c->detach('/hwasset/list_js');
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
