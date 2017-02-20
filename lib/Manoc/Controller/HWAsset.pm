# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
use strict;

package Manoc::Controller::HWAsset;
use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }

# Not using CommonCRUD
with 'Manoc::ControllerRole::ResultSet';
with 'Manoc::ControllerRole::ObjectForm';
with 'Manoc::ControllerRole::ObjectList';

with 'Manoc::ControllerRole::JSONView';
with 'Manoc::ControllerRole::JQDatatable';

use Manoc::DB::Result::HWAsset;

use Manoc::Form::HWAsset;

=head1 NAME

Manoc::Controller::HWAsset - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'hwasset',
        }
    },
    class      => 'ManocDB::HWAsset',
    form_class => 'Manoc::Form::HWAsset',

    json_columns =>
        [qw(id serial vendor model inventory rack_id rack_level building_id room label)],

    datatable_row_callback    => 'datatable_row',
    datatable_columns         => [qw(inventory type vendor model serial rack.name)],
    datatable_search_columns  => [qw(serial vendor model inventory)],
    datatable_search_options  => { prefetch => { 'rack' => 'building' } },
    datatable_search_callback => 'datatable_search_cb',

    object_list_filter_columns => [qw( type vendor rack_id building_id )],
);

=head1 ACTIONS

=head2 create_device

Create a new device using a form. Chained to base.

=cut

sub create_device : Chained('base') : PathPart('create_device') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{resultset}->new_result( {} );

    ## TODO better permission
    $c->require_permission( $object, 'create' );

    $c->stash(
        object          => $object,
        form_class      => 'Manoc::Form::HWAsset',
        form_parameters => { type => Manoc::DB::Result::HWAsset->TYPE_DEVICE },
    );
    $c->detach('form');
}

=head2 list

Display a list of items. Chained to base since the table is AJAX based

=cut

sub list : Chained('base') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{resultset}, 'list' );
}

=head2 list_devices

Display a list of items. Chained to base since the table is AJAX based

=cut

sub list_devices : Chained('base') : PathPart('devices') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{resultset}, 'list' );
}

=head2 view

Display a single items.

=cut

sub view : Chained('object') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};

    if ( $object->type eq Manoc::DB::Result::HWAsset->TYPE_SERVER ) {
        $c->res->redirect( $c->uri_for_action( 'serverhw/view', [ $object->serverhw->id ] ) );
        $c->detach();
    }

    $c->require_permission( $object, 'view' );
}

=head2 edit

Use a form to edit a row.

=cut

sub edit : Chained('object') : PathPart('update') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};
    $c->require_permission( $object, 'edit' );

    # redirect serverhw to specific controller
    if ( $object->type eq Manoc::DB::Result::HWAsset->TYPE_SERVER ) {
        $c->res->redirect( $c->uri_for_action( 'serverhw/edit', [ $object->serverhw->id ] ) );
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

=haed2 delete

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

=head2 decommission

=cut

=head2 decommission

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

=head2 restore

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

=head2 vendors_js

Get a list of vendors

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

=head2 models_js

Get a list of models optionally filtered by vendor

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

=head1 METHODS

=cut

sub get_form_process_params {
    my ( $self, $c, %params ) = @_;

    my $qp = $c->req->query_parameters;
    $qp->{hide_location} and $params{hide_location} = $qp->{hide_location};

    return %params;
}

sub datatable_search_cb {
    my ( $self, $c, $filter, $attr ) = @_;

    my $extra_filter = {};

    my $status = $c->request->param('search_status');
    if ( defined($status) ) {
        $status eq 'd' and
            $extra_filter->{location} = Manoc::DB::Result::HWAsset::LOCATION_DECOMMISSIONED;
        $status eq 'w' and
            $extra_filter->{location} = Manoc::DB::Result::HWAsset::LOCATION_WAREHOUSE;
        $status eq 'u' and
            $extra_filter->{location} = [
            -and => { '!=' => Manoc::DB::Result::HWAsset::LOCATION_DECOMMISSIONED },
            { '!=' => Manoc::DB::Result::HWAsset::LOCATION_WAREHOUSE }
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
        link      => $c->uri_for_action( $action, [ $row->id ] ),
    };
}

sub datatable_source_devices : Chained('base') : PathPart('datatable_source/devices') : Args(0)
{
    my ( $self, $c ) = @_;

    $c->stash->{'datatable_resultset'} = $c->stash->{resultset}->search_rs(
        {
            type => Manoc::DB::Result::HWAsset::TYPE_DEVICE,
        }
    );
    $c->forward('/hwasset/datatable_source');
}

sub unused_devices_js : Chained('base') : PathPart('js/device/unused') {
    my ( $self, $c ) = @_;

    my $rs = $c->stash->{resultset};
    $c->stash( object_list => [ $rs->unused_devices->all() ] );
    $c->detach('/hwasset/list_js');
}

=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
