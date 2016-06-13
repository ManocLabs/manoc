# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
use strict;

package Manoc::Controller::DHCPSubnet;
use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }
with 'Manoc::ControllerRole::CommonCRUD';

use Manoc::Form::DHCPSubnet;

=head1 NAME

Manoc::Controller::DHCPSubnet - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'dhcpsubnet',
        }
    },
    class      => 'ManocDB::DHCPSubnet',
    form_class => 'Manoc::Form::DHCPSubnet',
);


=head2 create

=cut

before 'create' => sub {
    my ( $self, $c ) = @_;

    my $net_id = $c->req->query_parameters->{'network_id'};
    $c->log->debug("new network $net_id in dhcp form");
    $c->stash( form_defaults => { network => $net_id } );
};


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
