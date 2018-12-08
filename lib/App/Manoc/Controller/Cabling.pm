package App::Manoc::Controller::Cabling;
#ABSTRACT: Cabling Controller

use Moose;

##VERSION

#TODO: if this controller should be used, it's jus for matrix view

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

with
    'App::Manoc::ControllerRole::ResultSet',
    'App::Manoc::ControllerRole::ObjectList',
    'App::Manoc::ControllerRole::ObjectSerializer',
    "App::Manoc::ControllerRole::JSONView";

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'cabling',
        }
    },
    class               => 'ManocDB::CablingMatrix',
    view_object_perm    => undef,
    object_list_options => { prefetch => [ 'interface2', 'serverhw_nic' ] },
);

=action list

Display a list of items.

=cut

sub list : Chained('object_list') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

}

=action list_js

=cut

sub list_js : Chained('object_list') : PathPart('js') : Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('object_list_js');
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
