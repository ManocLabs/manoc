package App::Manoc::Controller::CablingMatrix;
#ABSTRACT: CablingMatrix Controller

use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends 'App::Manoc::ControllerBase::CRUD'; }

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'cabling',
        }
    },
    class               => 'ManocDB::CablingMatrix',
    form_class          => 'App::Manoc::Form::DeviceCabling',
    view_object_perm    => undef,
    object_list_options => { prefetch => [ 'interface2', 'serverhw_nic' ] },
);

=action uncabled_iface_js


=cut

sub uncabled_iface_js : Chained('base') : PathPart('uncabled_iface/js') : Args(0) {
    my ( $self, $c ) = @_;

    $c->require_permission( $c->stash->{resultset}, 'list' );

    my $device = $c->req->query_parameters->{device};

    my $filter;

    my $q = $c->req->query_parameters->{'q'};
    $q and $filter->{name} = { -like => "$q%" };

    my @data =
        $c->$c->model('DeviceIface')->search_uncabled($device)->search( $filter, {} )->all();

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
