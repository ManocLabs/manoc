# Copyright 2017 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::APIv1::Workstation;
use Moose;
use namespace::autoclean;

=head1 NAME

Manoc::Controller::APIv1::DHCP - Catalyst Controller for DHCP APIs

=head1 DESCRIPTION

Catalyst Controller for implementing DHCP related web APIs.

=cut

BEGIN { extends 'Manoc::Controller::APIv1' }

=head1 METHODS

=cut

sub workstation_base : Chained('deserialize') PathPart('workstation') CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash( resultset => $c->model('ManocDB::Workstation') );
}

=head2 workstation_post

POST api/v1/workstation

=cut

sub workstation_post : Chained('workstation_base') PathPart('') POST {
    my ( $self, $c ) = @_;

    $c->stash(
        api_validate => {
            type  => 'hash',
            items => {
                name => {
                    type     => 'scalar',
                    required => 1,
                },
                installed_pkgs => {
                    type     => 'array',
                    required => 1,
                },
            },
        }
    );
    $c->forward('validate') or return;

    my $req_data = $c->stash->{api_request_data};

    my $name = $req_data->{server};
    my $workstation = $c->stash->{resultset}->find( { name => 'name' } );
    if ( !$workstation ) {
        push @{ $c->stash->{api_field_errors} }, "Unknown workstation $name";
        return;
    }

    my $data = { message => "Updated", };

    $c->stash( api_response_data => $data );
}

=head1 AUTHOR

The Manoc Team

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
