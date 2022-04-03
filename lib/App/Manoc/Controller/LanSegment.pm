package App::Manoc::Controller::LanSegment;
#ABSTRACT: LanSegment controller

use Moose;

##VERSION

use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }
with 'App::Manoc::ControllerRole::CommonCRUD';

use App::Manoc::Form::LanSegment;

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'lansegment',
        }
    },
    class      => 'ManocDB::LanSegment',
    form_class => 'App::Manoc::Form::LanSegment',

    object_list_options => {
        distinct  => 1,
        '+select' => [
            { count => 'vlans.id',   -as => 'vlan_count' },
            { count => 'devices.id', -as => 'device_count' }
        ],
        join => [ 'vlans', 'devices' ],
    }
);

=action view

Redirect to edit

=cut

sub view : Chained('object') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};
    $c->response->redirect( $c->uri_for_action( 'lansegment/edit', [ $object->id ] ) );
}

=method delete_object

=cut

sub delete_object {
    my ( $self, $c ) = @_;
    my $segment = $c->stash->{'object'};

    if ( $segment->vlans->count ) {
        $c->flash( error_msg => 'Segment has associated VLANs and cannot be deleted.' );
        return;
    }

    if ( $segment->vlan_ranges->count ) {
        $c->flash( error_msg => 'Segment has associated VLAN ranges and cannot be deleted.' );
        return;
    }

    if ( $segment->vlan_ranges->count ) {
        $c->flash( error_msg => 'Segment has associated devices and cannot be deleted.' );
        return;
    }

    return $segment->delete;
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
