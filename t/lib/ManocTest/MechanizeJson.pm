package ManocTest::MechanizeJson;
use Moose::Role;

use JSON::MaybeXS;

sub json_ok {
    my ( $self, $desc ) = @_;
    return $self->_json_ok( $desc, $self->content );
}

sub json {
    my ( $self, $text ) = @_;
    $text ||=
        exists $self->response->headers->{'x-json'} ? $self->response->headers->{'x-json'} :
        $self->content;
    my $json = eval { decode_json($text); };
    return $json;
}

sub _json_ok {
    my ( $self, $desc, $text ) = @_;
    my $json = $self->json($text);

    if ( not $desc ) {
        if ( defined $json and ref $json eq 'HASH' and not $@ ) {
            $desc = sprintf 'Got JSON from %s', $self->uri;
        }
        else {
            $desc = sprintf 'Not JSON from %s (%s)', $self->uri, $@;
        }
    }

    Test::Builder->new->ok( $json, $desc );

    return $json || undef;
}

no Moose::Role;
1;
