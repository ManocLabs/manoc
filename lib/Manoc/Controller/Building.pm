# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Building;
use Moose;
use namespace::autoclean;

use Manoc::Form::Building;

BEGIN { extends 'Catalyst::Controller'; }
with "Manoc::ControllerRole::CommonCRUD";
with "Manoc::ControllerRole::JSONView";

=head1 NAME

Manoc::Controller::Building - Catalyst Controller

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
    class      => 'ManocDB::Building',

    create_page_title  => 'New building',
    edit_page_title    => 'Edit building',
    list_page_title    => 'Buildings',
);

sub get_object_list {
   my ( $self, $c ) = @_;

   my $rs = $c->stash->{resultset};
   return  [ $rs->search({}, {prefetch => 'racks'} ) ];
}

sub get_form {
    my ( $self, $c ) = @_;
    return Manoc::Form::Building->new();
}

sub delete_object {
    my ( $self, $c ) = @_;
    my $building = $c->stash->{'object'};

    if ( $building->racks->count ) {
        $c->flash( error_msg => 'Building is not empty and cannot be deleted.' );
        return undef;
    }

    return  $building->delete;
}

sub prepare_json_object {
    my ($self, $building) = @_;
    return {
        id      => $building->id,
        name    => $building->name,
        description   => $building->description,
        racks   => [ map +{ id => $_->id, name => $_->name }, $building->racks ],
       },
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
