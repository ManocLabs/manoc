# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::View::Popup;

use strict;
use warnings;

use base 'Catalyst::View::TT';

=head1 NAME

Manoc::View::Popup - Catalyst View

=head1 DESCRIPTION

Catalyst View.

=head1 AUTHOR

Rigo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    INCLUDE_PATH       => [
        Manoc->path_to( 'root', 'src' ),
        Manoc->path_to( 'root', 'src', 'include' ),
        Manoc->path_to( 'root', 'src', 'forms' ),
    ],
    PRE_PROCESS => 'macros.tt',
    WRAPPER     => 'popup_wrapper.tt',
    render_die  => 1,
);

#__PACKAGE__->meta->make_immutable;

1;
