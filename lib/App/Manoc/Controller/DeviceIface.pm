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

=method get_form

=cut

before 'create' => sub {
    my ( $self, $c ) = @_;

    my $device_id = $c->{stash}->{object}->device_id;
    $c->stash( form_parameters => { device_id => $device_id } );
};

=method view2

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
