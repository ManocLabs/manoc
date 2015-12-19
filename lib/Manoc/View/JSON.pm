# Copyright 2013 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::View::JSON;

use strict;
use base 'Catalyst::View::JSON';

use JSON;

=head1 NAME

Manoc::View::JSON - Catalyst JSON View

=head1 SYNOPSIS

See L<Manoc>

=cut

__PACKAGE__->config( 'expose_stash' => 'json_data', );

sub encode_json($) {
    my ( $self, $c, $data ) = @_;

    if ( not defined($data) ) {
        $c->response->status(403);
        $c->detach();
        return undef;
    }

    # HACK we use latin1 to avoid a double uft8 encoding
    my $encoder = JSON->new->latin1();
    $encoder->allow_blessed(1);
    $encoder->convert_blessed(1);
    return $encoder->encode($data);
}

=head1 DESCRIPTION

Catalyst JSON View.

=head1 AUTHOR

gabriele

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
