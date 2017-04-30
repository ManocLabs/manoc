# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::View::TT::Plugin::JSON;

use strict;
use warnings;

use Template::Plugin;
use base 'Template::Plugin';
use JSON;

=head1 NAME

App::Manoc::View::TT::Plugin::JSON -  JSON Plugin for TT View

=head1 DESCRIPTION

JSON  utilities for Manoc TT View using L<JSON|JSON> module

=cut

sub json {
    my $self = shift;
    my $o    = shift;
    return JSON->new->convert_blessed(1)->encode($o);
}

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
