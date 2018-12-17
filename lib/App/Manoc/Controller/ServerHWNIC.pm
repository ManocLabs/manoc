package App::Manoc::Controller::ServerHWNIC;
#ABSTRACT: Interface Controller

use Moose;

##VERSION

BEGIN { extends 'Catalyst::Controller'; }

=head1 CONSUMED ROLES

=for :list
* App::Manoc::ControllerRole::CommonCRUD
* App::Manoc::ControllerRole::JSONView

=cut

BEGIN { extends 'Catalyst::Controller'; }

with 'App::Manoc::ControllerRole::CommonCRUD' =>
    { -excludes => [ 'list', 'list_js', 'create' ] };

use App::Manoc::Form::ServerHWNIC;

use namespace::autoclean;

__PACKAGE__->config(
    action => {
        setup => {
            PathPart => 'serverhwnic',
        }
    },
    class      => 'ManocDB::ServerHWNIC',
    form_class => 'App::Manoc::Form::ServerHWNIC'
);

=action cabling

=cut

sub cabling : Chained('object') : PathPart('cabling') : Args(0) {
    my ( $self, $c ) = @_;

    my $nic = $c->stash->{'object'};
    $c->require_permission( $nic->serverhw, 'view' );
    my $form = App::Manoc::Form::Cabling->new(
        {
            ctx => $c,
        }
    );
    $c->stash( form => $form );
}

=action list_uncabled_js

=cut

sub list_uncabled_js : Chained('base') : PathPart('uncabled') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{resultset}, 'list' );

    my $server_id   = $c->req->query_parameters->{'server'};
    my $serverhw_id = $c->req->query_parameters->{'serverhw'};
    my $q           = $c->req->query_parameters->{'q'};

    my $filter;
    $q and $filter->{name} = { -like => "$q%" };
    $server_id   and $filter->{'server.id'}      = $server_id;
    $serverhw_id and $filter->{'me.serverhw_id'} = $serverhw_id;

    my @ifaces =
        $self->get_resultset($c)->search_uncabled()
        ->search( $filter, { prefetch => { serverhw => 'server' } } )->all();

    my @data = map +{
        id       => $_->id,
        serverhw => {
            id    => $_->serverhw->id,
            label => $_->serverhw->label,
        },
        server => (
            $_->serverhw->server ?
                {
                id    => $_->serverhw->server->id,
                label => $_->serverhw->server->label
                } :
                {},
        ),
        name => $_->name
    }, @ifaces;

    $c->stash( json_data => \@data );
    $c->forward('View::JSON');
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
