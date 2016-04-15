# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::VTP;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

with 'Manoc::ControllerRole::ResultSet';
with 'Manoc::ControllerRole::ObjectList';

=head1 NAME

Manoc::Controller::VTP - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller for showing VTP entries.

=cut

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'vtp',
        }
    },
    class                   => 'ManocDB::VlanVtp',
    enable_permission_check => 1,
    view_object_perm        => undef,
);

=head1 METHODS

=head2 list

=cut

sub list : Chained('object_list') : PathPart('') : Args(0) {
    # just use defaults
}

=head2 no_vlan

=cut

sub compare : Chained('base') : PathPart('compare') : Args(0) {
    my ( $self, $c ) = @_;

    my $vtp_rs  = $c->stash->{resultset};
    my $vlan_rs = $c->model('ManocDB::Vlan');

    my @diff;

    # search vtp entries with missing or mismatched vlan
    my @vtp_entries = $vtp_rs->search(
        [ { 'vlan.id' => undef }, { 'vlan.name' => { '!=' => { -ident => 'me.name' } } } ],
        {
            prefetch => 'vlan'
        }
    );
    foreach my $vtp (@vtp_entries) {
        push @diff,
            {
            id        => $vtp->id,
            vlan_name => $vtp->vlan ? $vtp->vlan->name : '',
            vtp_name  => $vtp->name,
            };
    }

    # search vlans with missing vtp
    my @vlan_entries = $vlan_rs->search(
        {
            'vtp_entry.id' => undef,
        },
        {
            prefetch => 'vtp_entry',
        }
    );
    foreach my $vlan (@vlan_entries) {
        push @diff,
            {
            id        => $vlan->id,
            vlan_name => $vlan->name,
            vtp_name  => '',
            };
    }

    # sort diff entries by id
    @diff = sort { $a->{id} <=> $a->{id} } @diff;

    $c->stash( diff => \@diff );
}

=head2 get_object_list

=cut

sub get_object_list {
    my ( $self, $c ) = @_;

    my $rs      = $c->stash->{resultset};
    my @objects = $rs->search(
        {},
        {
            prefetch => 'vlan'
        }
    );
    return \@objects;
}

=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
