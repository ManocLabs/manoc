# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
use strict;

package Manoc::Controller::Server;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Controller';
with 'Manoc::ControllerRole::CommonCRUD';

use Manoc::Form::Server;

=head1 NAME

Manoc::Controller::Server - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'server',
        }
    },
    class                   => 'ManocDB::Server',
    form_class              => 'Manoc::Form::Server',
    enable_permission_check => 1,
    view_object_perm        => undef,
    json_columns            => [ 'id', 'name' ],
);


=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
