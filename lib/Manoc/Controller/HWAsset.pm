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

    json_columns => [ qw(id serial vendor model inventory rack_id rack_level building_id room label)],

    datatable_row_callback => 'datatable_row',
    datatable_search_columns => [  qw(serial vendor model inventory) ],

    object_list_filter_columns => [ qw( type vendor rack_id building_id ) ],
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
        form_parameters => { type => $Manoc::DB::Result::Device::TYPE_DEVICE },
    );
    $c->detach('form');
}

=head2 list

Display a list of items.

=cut

sub list : Chained('object_list') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{resultset}, 'list' );
}

=head2 view

Display a single items.

=cut

sub view : Chained('object') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};

    $c->require_permission( $object, 'view' );
}

=head2 edit

Use a form to edit a row.

=cut

sub edit : Chained('object') : PathPart('update') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};
    $c->require_permission( $object, 'edit' );

    #TODO redirect to specific forms if needed

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
            $c->res->redirect( $c->uri_for_action( 'hwasset/list' ));
            $c->detach();
        }
        else {
            $c->res->redirect( $c->uri_for_action( 'hwasset/view', [ $c->stash->{object_pk} ]));
            $c->detach();
        }
    }

}

=head1 METHODS

=cut

sub get_form_process_params {
    my ( $self, $c, %params ) = @_;

    my $qp =  $c->req->query_parameters;
    $qp->{hide_location} and $params{hide_location} = $qp->{hide_location};

    return %params;
}

sub datatable_row {
    my ($self, $c, $row) = @_;

    return {
        inventory => $row->inventory,
        type      => $row->display_type,
        vendor    => $row->vendor,
        model     => $row->model,
        serial    => $row->serial,
        location  => $row->display_location,
        link      => $c->uri_for_action('hwasset/view', [ $row->id ]),
    }
}

sub unused_devices_js : Chained('base') : PathPart('js/device/unused') {
    my ($self, $c) = @_;

    my $rs = $c->stash->{resultset};
    $c->stash(object_list => [ $rs->unused_devices->all() ]);
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
