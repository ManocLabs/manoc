# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::View::WebPage;

use strict;
use warnings;

use base 'Manoc::View::TTBase';

__PACKAGE__->config(
    WRAPPER     => 'wrapper.tt',
);

=head1 NAME

Manoc::View::WebPage - TT Based HTML View for Manoc

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
