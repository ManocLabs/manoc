# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
use strict;

package Manoc::Controller::Server;
use Moose;
use namespace::autoclean;

with 'Manoc::ControllerRole::CommonCRUD';



=head1 NAME

Manoc::Controller::Server - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut



=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
