package App::Manoc::View::TT::Plugin::JSON;

use strict;
use warnings;

##VERSION

use Template::Plugin;
use base 'Template::Plugin';
use JSON;

=head1 NAME

App::Manoc::View::TT::Plugin::JSON -  JSON Plugin for TT View

=head1 DESCRIPTION

JSON utilities for Manoc TT View using L<JSON|JSON> module

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
