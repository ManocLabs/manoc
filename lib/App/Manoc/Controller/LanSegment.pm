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

=head1 METHODS

=cut

=head2 delete_object

=cut

sub delete_object {
    my ( $self, $c ) = @_;
    my $segment = $c->stash->{'object'};

    if ( $segment->vlans->count ) {
        $c->flash( error_msg => 'Segment has associated VLANs and cannot be deleted.' );
        return undef;
    }

    if ( $segment->vlan_ranges->count ) {
        $c->flash( error_msg => 'Segment has associated VLAN ranges and cannot be deleted.' );
        return undef;
    }

    if ( $segment->vlan_ranges->count ) {
        $c->flash( error_msg => 'Segment has associated devices and cannot be deleted.' );
        return undef;
    }

    return $segment->delete;
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
