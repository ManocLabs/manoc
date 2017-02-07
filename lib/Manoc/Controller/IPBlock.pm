# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
use strict;

package Manoc::Controller::IPBlock;
use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }

with 'Manoc::ControllerRole::CommonCRUD';
with 'Manoc::ControllerRole::ObjectForm';
with 'Manoc::ControllerRole::JSONView';

use Manoc::Form::IPBlock;

use Manoc::Utils::Datetime qw(str2seconds);

=head1 NAME

Manoc::Controller::IPBlock - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'ipblock',
        }
    },
    class                   => 'ManocDB::IPBlock',
    form_class              => 'Manoc::Form::IPBlock',
    enable_permission_check => 1,
    view_object_perm        => undef,
    json_columns            => [qw( id name from_addr to_addr )],
);

before 'view' => sub {
    my ( $self, $c ) = @_;

    my $block     = $c->stash->{object};
    my $max_hosts = $block->to_addr->numeric - $block->from_addr->numeric + 1;

    my $query_by_time = { lastseen => { '>=' => time - str2seconds( 60, 'd' ) } };
    my $select_column = {
        columns  => [qw/ipaddr/],
        distinct => 1
    };
    my $arp_60days = $block->arp_entries->search( $query_by_time, $select_column )->count();
    $c->stash( arp_usage60 => int( $arp_60days / $max_hosts * 100 ) );

    my $arp_total = $block->arp_entries->search( {}, $select_column )->count();
    $c->stash( arp_usage => int( $arp_total / $max_hosts * 100 ) );

    my $hosts = $block->ip_entries;
    $c->stash( hosts_usage => int( $hosts->count() / $max_hosts * 100 ) );
};

sub arp : Chained('object') {
    my ( $self, $c ) = @_;

    my $block = $c->stash->{object};

    # override default title
    $c->stash( title => 'ARP activity for block ' . $block->name );

    $c->detach('/arp/list');
}

sub arp_js : Chained('object') {
    my ( $self, $c ) = @_;

    my $block = $c->stash->{object};
    my $days  = int( $c->req->param('days') );

    my $rs = $block->arp_entries->first_last_seen();
    if ($days) {
        $rs = $rs->search( { lastseen => time - str2seconds( $days, 'd' ) } );
    }
    $c->stash( datatable_resultset => $rs );

    $c->detach('/arp/list_js');
}

=head2 create_ipblock

Create a new device using a form. Chained to base.

=cut

sub create_ipblock : Chained('base') : PathPart('create_ipblock') : Args(0) {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{resultset}->new_result( {} );

    ## TODO better permission
    $c->require_permission( $object, 'create' );

    $c->stash(
        object     => $object,
        form_class => 'Manoc::Form::IPBlock',
    );
    $c->detach('form');
}

sub ipblocks_js : Chained('base') : PathPart('js/ipblock/list') {
    my ( $self, $c ) = @_;

    my $rs = $c->stash->{resultset};
    $c->stash( object_list => [ $rs->search( {} )->all() ] );
    $c->detach('/ipblock/list_js');
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
