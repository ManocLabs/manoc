package App::Manoc::View::JSON;

use strict;
use warnings;

##VERSION

use base 'Catalyst::View::JSON';

use JSON qw();

=head1 NAME

App::Manoc::View::JSON - Catalyst JSON View

=head1 SYNOPSIS

See L<Manoc>

=cut

__PACKAGE__->config( 'expose_stash' => 'json_data', );

sub encode_json {
    my ( $self, $c, $data ) = @_;

    if ( not defined($data) ) {
        $c->response->status(403);
        $c->detach();
        return;
    }

    my $encoder = JSON->new->utf8();
    $encoder->allow_blessed(1);
    $encoder->convert_blessed(1);
    return $encoder->encode($data);
}

=head1 DESCRIPTION

Catalyst JSON View.

=cut

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
