# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
use strict;

package Manoc::Controller::Warehouse;
use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }
with 'Manoc::ControllerRole::CommonCRUD';
with "Manoc::ControllerRole::JSONView";

use Manoc::Form::Warehouse;

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'warehouse',
        }
    },
    class                   => 'ManocDB::Warehouse',
    form_class              => 'Manoc::Form::Warehouse',
    enable_permission_check => 1,
    view_object_perm        => undef,
    json_columns            => [ 'id', 'name' ],
);

=head1 NAME

Manoc::Controller::Warehouse - Catalyst Controller

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

=head2 delete_object

=cut

sub delete_object {
    my ( $self, $c ) = @_;

    my $warehouse = $c->stash->{'object'};

    if ( $warehouse->devices->count ) {
        $c->flash( error_msg => "Warehouse is not empty. Cannot be deleted." );
        return undef;
    }

    return $warehouse->delete;
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
