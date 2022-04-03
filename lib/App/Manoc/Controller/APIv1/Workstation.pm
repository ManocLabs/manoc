package App::Manoc::Controller::APIv1::Workstation;
#ABSTRACT: Controller for DHCP APIs

use Moose;
##VERSION

use namespace::autoclean;

BEGIN { extends 'App::Manoc::ControllerBase::APIv1CRUD' }

use App::Manoc::Form::Workstation::Edit;

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'workstation',
        }
    },
    class      => 'ManocDB::Workstation',
    form_class => 'App::Manoc::Form::Workstation::Edit',
);

__PACKAGE__->meta->make_immutable;

=action workstation_post

POST api/v1/workstation/discovery

=cut

sub workstation_post : Chained('base') PathPart('discovery') POST {
    my ( $self, $c ) = @_;

    $c->stash(
        api_validate => {
            type  => 'hash',
            items => {
                name => {
                    type     => 'scalar',
                    required => 1,
                },
                installed_pkgs => {
                    type     => 'array',
                    required => 1,
                },
            },
        }
    );
    $c->forward('validate') or return;

    my $req_data = $c->stash->{api_request_data};

    my $name        = $req_data->{server};
    my $workstation = $c->stash->{resultset}->find( { name => 'name' } );
    if ( !$workstation ) {
        push @{ $c->stash->{api_field_errors} }, "Unknown workstation $name";
        return;
    }

    my $data = { message => "Updated", };

    $c->stash( api_response_data => $data );
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
