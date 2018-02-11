package App::Manoc::View::JSON;

use strict;
use warnings;

##VERSION

use base 'Catalyst::View::JSON';

use JSON qw();

=head1 NAME

App::Manoc::View::JSON - Catalyst JSON View

=head1 SYNOPSIS

  sub list_js : Chained('object_list') : PathPart('js') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( json_data => \@my_list );
    $c->forward('View::JSON');
  }

=cut

__PACKAGE__->config( 'expose_stash' => 'json_data', );

=for Pod::Coverage encode_json
=cut

sub encode_json {
    my ( $self, $c, $data ) = @_;

    if ( not defined($data) ) {
        $c->response->status(403);
        $c->detach();
        return;
    }

    my $encoder = JSON::MaybeXS->new(
        utf8            => 1,
        allow_blessed   => 1,
        convert_blessed => 1,
    );
    return $encoder->encode($data);
}

=head1 SEE ALSO

L<Catalyst::View::JSON>

=cut

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
