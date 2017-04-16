# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Workstation;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

with 'Manoc::ControllerRole::CommonCRUD',
    "Manoc::ControllerRole::JQDatatable",
    "Manoc::ControllerRole::JSONView",
    "Manoc::ControllerRole::CSVView";

use Manoc::Form::Workstation::Edit;
use Manoc::Form::Workstation::Decommission;

=head1 NAME

Manoc::Controller::Workstation - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'workstation',
        }
    },
    class                   => 'ManocDB::Workstation',
    form_class              => 'Manoc::Form::Workstation::Edit',
    enable_permission_check => 1,
    view_object_perm        => undef,
    json_columns            => [ 'id', 'name' ],

    create_page_title => 'Create workstation',
    edit_page_title   => 'Edit workstation',

    csv_columns => [ 'hostname', 'os', 'os_ver', 'notes' ],

    datatable_row_callback    => 'datatable_row',
    datatable_search_columns  => [qw( hostname os os_ver hwasset.model )],
    datatable_search_options  => { prefetch => { workstationhw => 'hwasset' } },
    datatable_search_callback => 'datatable_search_cb',

);

=head2 create

=cut

before 'create' => sub {
    my ( $self, $c ) = @_;

    my $hardware_id = $c->req->query_parameters->{'hardware_id'};

    my %form_defaults;
    if ( defined($hardware_id) ) {
        $c->log->debug("new workstation using hardware $hardware_id") if $c->debug;
        $form_defaults{hardware} = $hardware_id;
    }

    %form_defaults and
        $c->stash( form_defaults => \%form_defaults );
};

=head2 edit

=cut

before 'edit' => sub {
    my ( $self, $c ) = @_;

    my $object    = $c->stash->{object};
    my $object_pk = $c->stash->{object_pk};

    # decommissioned objects cannot be edited
    if ( $object->decommissioned ) {
        $c->res->redirect( $c->uri_for_action( 'workstation/view', [$object_pk] ) );
        $c->detach();
    }
};

=head2 import_csv

Import a workstation hardware list from a CSV file

=cut

sub import_csv : Chained('base') : PathPart('importcsv') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( 'workstation', 'create' );
    my $rs = $c->stash->{resultset};

    my $upload;
    $c->req->method eq 'POST' and $upload = $c->req->upload('file');

    my $form = Manoc::Form::CSVImport::WorkstationHW->new(
        ctx       => $c,
        resultset => $rs,
    );
    $c->stash->{form} = $form;

    my %process_params;
    $process_params{params} = $c->req->parameters;
    $upload and $process_params{params}->{file} = $upload;
    my $process_status = $form->process(%process_params);

    return unless $process_status;
}

=head2 decommission

=cut

sub decommission : Chained('object') : PathPart('decommission') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{object}, 'edit' );

    my $form = Manoc::Form::Workstation::Decommission->new( { ctx => $c } );

    $c->stash(
        form   => $form,
        action => $c->uri_for( $c->action, $c->req->captures ),
    );
    return unless $form->process(
        item   => $c->stash->{object},
        params => $c->req->parameters,
    );

    $c->response->redirect(
        $c->uri_for_action( 'workstation/view', [ $c->stash->{object_pk} ] ) );
    $c->detach();
}

=head2 restore

=cut

sub restore : Chained('object') : PathPart('restore') : Args(0) {
    my ( $self, $c ) = @_;

    my $workstation = $c->stash->{object};
    $c->require_permission( $workstation, 'edit' );

    my $object_url = $c->uri_for_action( 'workstation/view', [ $workstation->id ] );

    if ( !$workstation->decommissioned ) {
        $c->response->redirect($object_url);
        $c->detach();
    }

    if ( $c->req->method eq 'POST' ) {
        $workstation->restore;
        $c->flash( message => "Workstation restored" );
        $c->response->redirect($object_url);
        $c->detach();
    }

    # show confirm page
    $c->stash(
        title           => 'Restore workstation',
        confirm_message => 'Restore decommissioned workstation ' . $workstation->label . '?',
        template        => 'generic_confirm.tt',
    );
}

=head1 METHODS

=cut

sub datatable_search_cb {
    my ( $self, $c, $filter, $attr ) = @_;

    my $extra_filter = {};

    my $status = $c->request->param('search_status');
    if ( defined($status) ) {
        $status eq 'd' and
            $extra_filter->{decommissioned} = 1;
        $status eq 'u' and
            $extra_filter->{decommissioned} = 0;
    }

    %$extra_filter and
        $filter = { -and => [ $filter, $extra_filter ] };

    return ( $filter, $attr );
}

sub datatable_row {
    my ( $self, $c, $row ) = @_;

    my $json_data = {
        hostname => $row->hostname,
        os       => $row->os,
        href     => $c->uri_for_action( 'workstation/view', [ $row->id ] ),
        hardware => undef
    };
    if ( my $hw = $row->workstationhw ) {
        $json_data->{hardware} = {
            label    => $hw->label,
            href     => $c->uri_for_action( 'workstationhw/view', [ $hw->id ] ),
            location => $hw->display_location
        };
    }

    return $json_data;
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
