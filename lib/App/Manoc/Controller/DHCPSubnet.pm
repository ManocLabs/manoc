package App::Manoc::Controller::DHCPSubnet;
#ABSTRACT: DHCPSubnet Controller

use Moose;

##VERSION

use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }
with
    'App::Manoc::ControllerRole::ResultSet',
    'App::Manoc::ControllerRole::ObjectForm';

use App::Manoc::Form::DHCPSubnet;

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'dhcpsubnet',
        }
    },
    class      => 'ManocDB::DHCPSubnet',
    form_class => 'App::Manoc::Form::DHCPSubnet',

);

=action create

Create a new object using a form. Chained to base.

=cut

sub create : Chained('base') : PathPart('create') : Args(0) {
    my ( $self, $c ) = @_;

    my $net_id    = $c->req->query_parameters->{'network_id'};
    my $server_id = $c->req->query_parameters->{'server_id'};
    my %form_defaults;

    $c->require_permission('dhcpserver.edit');

    if ( !defined($server_id) || !$c->model('ManocDB::DHCPServer')->find($server_id) ) {
        $c->response->redirect( $c->uri_for_action('dhcpserver/list') );
        $c->detach();
    }
    else {
        $form_defaults{dhcp_server} = $server_id;
    }

    defined($net_id) and $form_defaults{network} = $net_id;

    my $object = $c->stash->{resultset}->new_result( {} );
    $c->stash(
        server_id     => $server_id,
        form_defaults => \%form_defaults,
        object        => $object,
        title         => 'Create DHCP Subnet',
        template      => 'dhcpsubnet/create.tt',
    );

    $c->forward('object_form');
}

=action view

Display a single items.

=cut

sub view : Chained('object') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $c->require_permission('dhcpserver.view');
}

=action edit

Use a form to edit a row.

=cut

sub edit : Chained('object') : PathPart('update') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission('dhcpserver.edit');
    $c->forward('object_form');
}

=action delete

=cut

sub delete : Chained('object') : PathPart('delete') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission('dhcpserver.edit');

    if ( $c->req->method eq 'POST' ) {
        if ( $c->stash->{object}->delete ) {
            $c->flash( message => $self->object_deleted_message );
            $c->res->redirect(
                $c->uri_for_action( 'dhcpserver/view', [ $c->stash->{server_id} ] ) );
        }
        else {
            $c->res->redirect(
                $c->uri_for_action( 'dhcpsubnet/view', [ $c->stash->{object_pk} ] ) );
        }

        $c->detach();
    }
}

=action get_form_success_url

=cut

sub get_form_success_url {
    my ( $self, $c ) = @_;
    return $c->uri_for_action( 'dhcpserver/view', [ $c->stash->{object}->dhcp_server->id ] );
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
