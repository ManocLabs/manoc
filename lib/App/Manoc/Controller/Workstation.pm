package App::Manoc::Controller::Workstation;
#ABSTRACT: Workstation controller
use Moose;

##VERSION

=head1 DESCRIPTION

Workstation CRUD controller using for the C</workstation> path.

=cut

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 CONSUMED ROLES

=for :list
* App::Manoc::ControllerRole::CommonCRUD
* App::Manoc::ControllerRole::JQDatatable
* App::Manoc::ControllerRole::JSONView
* App::Manoc::ControllerRole::CSVView

=cut

with "App::Manoc::ControllerRole::CommonCRUD",
    "App::Manoc::ControllerRole::JQDatatable",
    "App::Manoc::ControllerRole::JSONView",
    "App::Manoc::ControllerRole::CSVView";

use App::Manoc::Form::Workstation::Edit;
use App::Manoc::Form::Workstation::Decommission;

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'workstation',
        }
    },
    class                   => 'ManocDB::Workstation',
    form_class              => 'App::Manoc::Form::Workstation::Edit',
    enable_permission_check => 1,
    view_object_perm        => undef,
    json_columns            => [ 'id', 'hostname', 'os', 'os_ver' ],

    create_page_title => 'Create workstation',
    edit_page_title   => 'Edit workstation',

    csv_columns => [ 'hostname', 'os', 'os_ver', 'notes' ],

    datatable_row_callback    => 'datatable_row',
    datatable_search_columns  => [qw( hostname os os_ver hwasset.model )],
    datatable_search_options  => { prefetch => { workstationhw => 'hwasset' } },
    datatable_search_callback => 'datatable_search_cb',

);

=action create

Override C<create> action to support hardware_id form default.
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

=action edit

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

=action import_csv

Import a workstation hardware list from a CSV file

=cut

sub import_csv : Chained('base') : PathPart('importcsv') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( 'workstation', 'create' );
    my $rs = $c->stash->{resultset};

    my $upload;
    $c->req->method eq 'POST' and $upload = $c->req->upload('file');

    my $form = App::Manoc::Form::CSVImport::WorkstationHW->new(
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

=action decommission

=cut

sub decommission : Chained('object') : PathPart('decommission') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{object}, 'edit' );

    my $form = App::Manoc::Form::Workstation::Decommission->new( { ctx => $c } );

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

=action restore

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

=method datatable_search_cb

Update datatable filter using search_status

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

=method datatable_row

Create a row object for datatable adding hardware info resolving href.

=cut

sub datatable_row {
    my ( $self, $c, $row ) = @_;

    my $json_data = {
        hostname => $row->hostname,
        os       => $row->os,
        href     => $c->uri_for_action( 'workstation/view', [ $row->id ] )->as_string,
        hardware => undef
    };
    if ( my $hw = $row->workstationhw ) {
        $json_data->{hardware} = {
            label    => $hw->label,
            href     => $c->uri_for_action( 'workstationhw/view', [ $hw->id ] )->as_string,
            location => $hw->display_location
        };
    }

    return $json_data;
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
