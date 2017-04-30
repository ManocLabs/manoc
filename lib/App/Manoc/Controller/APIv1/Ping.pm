package App::Manoc::Controller::APIv1::Ping;
use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends 'App::Manoc::Controller::APIv1' }

sub ping : Chained('deserialize') PathPart('ping') Args(0) GET {
    my ( $self, $c ) = @_;

    my $data = {
        request   => $c->stash->{request_data},
        timestamp => time,
    };

    $c->stash( api_response_data => $data );
}

sub ping_post : Chained('deserialize') PathPart('ping') Args(0) POST {
    my ( $self, $c ) = @_;

    my $data = {
        request   => $c->stash->{api_request_data},
        timestamp => time,
    };

    $c->stash( api_response_data => $data );
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
