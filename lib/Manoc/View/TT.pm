# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::View::TT;;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    INCLUDE_PATH       => [
        Manoc->path_to( 'root', 'src' ),
        Manoc->path_to( 'root', 'src', 'include' ),
        Manoc->path_to( 'root', 'src', 'pages' ),
        Manoc->path_to( 'lib', 'Manoc', 'Plugin'),
    ],
    PRE_PROCESS => 'init.tt',
    WRAPPER     => 'wrapper.tt',
    render_die  => 1,
);

=head1 NAME

Manoc::View::TT - TT View for Manoc

=head1 DESCRIPTION

TT View for Manoc.

=head1 SEE ALSO

L<Manoc>

=head1 AUTHOR

gabriele

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
