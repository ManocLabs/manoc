package App::Manoc::ControllerBase::CRUD;
#ABSTRACT: Base class for API controllers

use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

with 'App::Manoc::ControllerRole::CommonCRUD';

=head1 DESCRIPTION

This class can be used as a base for controllers using the L<App::Manoc::ControllerRole::CommonCRUD> role.

=cut

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
