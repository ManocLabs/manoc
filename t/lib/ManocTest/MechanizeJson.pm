package ManocTest::MechanizeJson;
use Moose::Role;

use JSON;

my $TB = Test::Builder->new();

=head2 json_ok( $desc  )

=cut

sub json_ok {
    my ( $self, $desc ) = @_;
    return $self->_json_ok( $desc, $self->content );
}

=head2 json( [ $text ] )

=cut

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
        if ( defined $json and ref($json) and not $@ ) {
            $desc = sprintf 'Got JSON from %s', $self->uri;
        }
        else {
            $desc = sprintf 'Not JSON from %s (%s)', $self->uri, $@;
        }
    }
    $TB->ok( $json, $desc );

    return $json || undef;
}

=head2 post_json_ok( $url, $content, [ \%LWP_options], $desc )

=cut

sub post_json_ok {
    my $self    = shift;
    my $url     = shift;
    my $content = shift;

    my $desc;
    my %opts;
    if (@_) {
        my $flex = shift;    # The flexible argument

        if ( !defined($flex) ) {
            $desc = shift;
        }
        elsif ( ref $flex eq 'HASH' ) {
            %opts = %{$flex};
            $desc = shift;
        }
        elsif ( ref $flex eq 'ARRAY' ) {
            %opts = @{$flex};
            $desc = shift;
        }
        else {
            $desc = $flex;
        }
    }    # parms left

    if ( not defined $desc ) {
        $url  = $url->url if ref($url) eq 'WWW::Mechanize::Link';
        $desc = "POST json $url";
    }

    my $json = encode_json($content);

    $self->post( $url, 'Content-Type' => 'application/json', Content => $json, %opts );
    my $ok = $self->success;

    $TB->ok( $ok, $desc );
    $TB->diag( $self->status );

    return $ok;
}

no Moose::Role;
1;
