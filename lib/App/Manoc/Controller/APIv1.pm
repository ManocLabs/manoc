# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Controller::APIv1;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use App::Manoc::Utils::Validate;

=head1 NAME

App::Manoc::Controller::APIv1 - Base class for API controllers

=head1 DESCRIPTION

This class should be used for implementing API controllers which manage entry point in api/v1.
It disables csrf and requires HTTP authentication.

Responses are generated using api_response_data stash element.

Error messages can be stored in api_message or api_field_errors for
input validatiation error.

=cut

has use_json_boolean => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub begin : Private {
    my ( $self, $c ) = @_;
    $c->stash( is_api => 1 );
}

sub base : Chained('/') PathPart('api/v1') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    # require HTTP Authentication
    $c->user_exists or
        $c->authenticate( {}, 'agent' );
}

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

=head1 NAME

App::Manoc::Controller::APIv1 - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=encoding utf8

=head1 AUTHOR

Gabriele

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
