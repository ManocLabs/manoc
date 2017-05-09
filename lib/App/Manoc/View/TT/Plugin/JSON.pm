package App::Manoc::View::TT::Plugin::JSON;
#ABSTRACT: Template::Plugin::JSON - Adds a .json vmethod to TT values.
use strict;
use warnings;

##VERSION

use Template::Plugin;
use base 'Template::Plugin';
use JSON;

=head1 DESCRIPTION

This plugin provides a C<.json> vmethod to all value types when loaded.

=cut

=method json

The C<.json> vmethod.

=cut

sub json {
    my $self = shift;
    my $o    = shift;
    return JSON->new->convert_blessed(1)->encode($o);
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
