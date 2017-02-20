# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
use strict;

package Manoc::Controller::Rack;
use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }
with 'Manoc::ControllerRole::CommonCRUD';
with "Manoc::ControllerRole::JSONView" => { -excludes => 'get_json_object', };

use Manoc::Form::Rack;

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'rack',
        }
    },
    class                   => 'ManocDB::Rack',
    form_class              => 'Manoc::Form::Rack',
    enable_permission_check => 1,
    view_object_perm        => undef,
    json_columns            => [ 'id', 'name' ],
);

=head1 NAME

Manoc::Controller::Rack - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 get_object_list

=cut

sub get_object_list {
    my ( $self, $c ) = @_;

    return [
        $c->stash->{resultset}->search(
            {},
            {
                prefetch => 'building',
                join     => 'building',
                order_by => 'me.name',
            }
        )
    ];
}

=head2 create

=cut

before 'create' => sub {
    my ( $self, $c ) = @_;

    my $building_id = $c->req->query_parameters->{'building'};
    $building_id and $c->log->debug("new rack in $building_id");
    $c->stash( form_defaults => { building => $building_id } );
};

=head2 delete_object

=cut

sub delete_object {
    my ( $self, $c ) = @_;

    my $rack = $c->stash->{'object'};

    if ( $rack->hwassets->count ) {
        $c->flash( error_msg => "Rack contains hardware assets. Cannot be deleted." );
        return undef;
    }
    if ( $rack->devices->count ) {
        $c->flash( error_msg => "Rack has associated devices. Cannot be deleted." );
        return undef;
    }

    return $rack->delete;
}

=head2 get_json_object

=cut

sub get_json_object {
    my ( $self, $c, $rack ) = @_;

    my $r = $self->prepare_json_object( $c, $rack );
    $r->{building} = {
        id   => $rack->building->id,
        name => $rack->building->name,
    };
    $r->{devices} = [ map +{ id => $_->id, name => $_->name }, $rack->devices ];
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
