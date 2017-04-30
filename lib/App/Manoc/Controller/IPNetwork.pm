# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
use strict;

package App::Manoc::Controller::IPNetwork;
use Moose;
use namespace::autoclean;

BEGIN {
    extends 'Catalyst::Controller';
}

with 'App::Manoc::ControllerRole::CommonCRUD';

use App::Manoc::Form::IPNetwork;
use App::Manoc::Utils::Datetime qw/str2seconds/;

=head1 NAME

App::Manoc::Controller::IPNetwork - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'ipnetwork',
        }
    },
    class                   => 'ManocDB::IPNetwork',
    form_class              => 'App::Manoc::Form::IPNetwork',
    enable_permission_check => 1,
    view_object_perm        => undef,
);

=head1 METHODS

=cut

sub get_object_list {
    my ( $self, $c ) = @_;

    my $rs = $c->stash->{resultset};
    return [
        $rs->search(
            {},
            {
                prefetch => 'vlan',
                order_by => { -asc => 'address' }
            }
        )->all()
    ];
}

before 'view' => sub {
    my ( $self, $c ) = @_;

    my $network   = $c->stash->{object};
    my $max_hosts = $network->network->num_hosts;

    my $query_by_time = { lastseen => { '>=' => time - str2seconds( 60, 'd' ) } };
    my $select_column = {
        columns  => [qw/ipaddr/],
        distinct => 1
    };
    my $arp_60days = $network->arp_entries->search( $query_by_time, $select_column )->count();
    $c->stash( arp_usage60 => int( $arp_60days / $max_hosts * 100 ) );

    my $arp_total = $network->arp_entries->search( {}, $select_column )->count();
    $c->stash( arp_usage => int( $arp_total / $max_hosts * 100 ) );

    my $hosts = $network->ip_entries;
    $c->stash( hosts_usage => int( $hosts->count() / $max_hosts * 100 ) );
};

sub arp : Chained('object') {
    my ( $self, $c ) = @_;

    my $network = $c->stash->{object};

    # override default title
    $c->stash( title => 'ARP activity for Network ' . $network->name );

    $c->detach('/arp/list');
}

sub arp_js : Chained('object') {
    my ( $self, $c ) = @_;

    my $network = $c->stash->{object};
    my $days    = int( $c->req->param('days') );

    my $rs = $network->arp_entries->first_last_seen();
    if ($days) {
        $rs = $rs->search( { lastseen => time - str2seconds( $days, 'd' ) } );
    }
    $c->stash( datatable_resultset => $rs );

    $c->detach('/arp/list_js');
}

sub root : Chained('base') {
    my ( $self, $c ) = @_;

    my $rs = $c->stash->{resultset};

    my $n_roots = $rs->get_root_networks->count();
    if ( $n_roots == 1 ) {
        my $root = $rs->get_root_networks->first;

        $c->stash( root_network => $root );
        $rs = $root->children;
    }
    else {
        $rs = $rs->get_root_networks;
    }

    my $me       = $rs->current_source_alias;
    my @networks = $rs->search(
        {},
        {
            prefetch => [ 'vlan', 'children' ],
            order_by => [
                { -asc  => "$me.address" },
                { -desc => "$me.broadcast" },
                { -asc  => "children.address" },
                { -desc => "children.broadcast" },
            ]
        }
    )->all();
    $c->stash( networks => \@networks );
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
