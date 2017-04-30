# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Controller::Building;
use Moose;
use namespace::autoclean;

use App::Manoc::Form::Building;

BEGIN { extends 'Catalyst::Controller'; }
with "App::Manoc::ControllerRole::CommonCRUD";
with "App::Manoc::ControllerRole::JSONView" => { -excludes => 'get_json_object', };

=head1 NAME

App::Manoc::Controller::Building - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'building',
        }
    },
    class                   => 'ManocDB::Building',
    form_class              => 'App::Manoc::Form::Building',
    enable_permission_check => 1,
    view_object_perm        => undef,
    json_columns            => [ 'id', 'name', 'description', 'label' ],
);

sub get_object_list {
    my ( $self, $c ) = @_;

    my $rs = $c->stash->{resultset};
    return [ $rs->search( {}, { prefetch => 'racks' } ) ];
}

sub delete_object {
    my ( $self, $c ) = @_;
    my $building = $c->stash->{'object'};

    if ( $building->warehouses->count ) {
        $c->flash( error_msg => 'Building has associated warehouses and cannot be deleted.' );
        return undef;
    }

    if ( $building->racks->count ) {
        $c->flash( error_msg => 'Building has associated racks and cannot be deleted.' );
        return undef;
    }

    return $building->delete;
}

sub get_json_object {
    my ( $self, $c, $building ) = @_;

    my $r = $self->prepare_json_object( $c, $building );
    $r->{racks} = [ map +{ id => $_->id, name => $_->name }, $building->racks ];
    return $r;
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
