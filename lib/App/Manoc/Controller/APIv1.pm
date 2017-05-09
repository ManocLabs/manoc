package App::Manoc::Controller::APIv1;
#ABSTRACT: Base class for API controllers

use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use App::Manoc::Utils::Validate;

=head1 DESCRIPTION

This class should be used for implementing API controllers which manage entry point in api/v1.
It disables CRSF and requires HTTP authentication.

Data can be validated using L<App::Manoc::Utils::Validate> via
C<validate> method.

Responses are generated using C<api_response_data> stash element.

Error messages are be stored in C<api_message> or C<api_field_errors>.

=head1 SYNOPSIS

  package App::Manoc::APIv1::FooApi;

  BEGIN { extends 'App::Manoc::Controller::APIv1' }

  sub foo_base : Chained('deserialize') PathPart('foo') CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( resultset => $c->model('ManocDB::Foo') );
  }

  sub foo_post : Chained('foo_base') PathPart('') POST {
    my ( $self, $c ) = @_;

    $c->stash(
        api_validate => {
            type  => 'hash',
            items => {
                foo_name => {
                    type     => 'scalar',
                    required => 1,
                },
                bar_list => {
                    type     => 'array',
                    required => 1,
                },
            },
        }
    );

=cut

has use_json_boolean => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

=method begin

Set is_api in stash

=cut

sub begin : Private {
    my ( $self, $c ) = @_;
    $c->stash( is_api => 1 );
}

=action base

Path api/v1. Require HTTP Authentication

=cut

sub base : Chained('/') PathPart('api/v1') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    # require HTTP Authentication
    $c->user_exists or
        $c->authenticate( {}, 'agent' );
}

=method deserialize

Chained to base, stores request body data in C<api_request_data> in stash.

=cut

sub deserialize : Chained('base') CaptureArgs(0) PathPart('') {
    my ( $self, $c ) = @_;

    if ( $c->req->body_data && scalar( keys %{ $c->req->body_data } ) ) {
        $c->log->debug('Deserializing body data for API input');
        $c->stash( api_request_data => $c->req->body_data );
    }
    else {
        $c->log->debug('No body data for API input');
    }
}

=method end

Genereates http status code preparare data (API results or validation
errors) for JSON serializer.

=cut

sub end : Private {
    my ( $self, $c ) = @_;

    my $expose_stash = 'json_data';

    # don't change the http status code if already set elsewhere
    unless ( $c->res->status && $c->res->status != 200 ) {
        if ( $c->stash->{api_field_errors} ) {
            $c->res->status(422);
        }
        elsif ( $c->stash->{api_error_message} ) {
            $c->res->status(400);
        }
        else {
            $c->res->status(200);
        }
    }

    if ( $c->res->status == 200 ) {
        $c->log->debug("Building response");
        my $data = $c->stash->{api_response_data};
        $c->stash->{$expose_stash} = $data;
    }
    else {
        # build the response data using error message
        $c->log->debug("Building error response");
        my $data          = {};
        my $field_errors  = $c->stash->{api_field_errors};
        my $error_message = $c->stash->{api_error_message} ||
            'Error processing request';

        if ( $field_errors and scalar(@$field_errors) ) {
            push @{ $data->{errors} }, @{$field_errors};
        }

        $c->stash->{$expose_stash} = $data;
    }

    $c->forward('View::JSON');
}

=method validate

Read data from C<api_request_data> stash value and validates with
L<App::Manoc::Utils::Validate> using rules in C<api_validate> stash
value.

=cut

sub validate : Private {
    my ( $self, $c ) = @_;

    my $data  = $c->stash->{api_request_data};
    my $rules = $c->stash->{api_validate};

    my $result = App::Manoc::Utils::Validate::validate( $data, $rules );
    if ( !$result->{valid} ) {
        $c->stash( api_field_errors => $result->{errors} );
        return 0;
    }
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
