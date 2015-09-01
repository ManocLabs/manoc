# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
use strict;

package Manoc::Controller::IPNetwork;
use Moose;
use namespace::autoclean;

BEGIN {
    extends 'Catalyst::Controller';
}

with 'Manoc::ControllerRole::CommonCRUD';

use Manoc::Form::IPNetwork;

=head1 NAME

Manoc::Controller::IPNetwork - Catalyst Controller

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
    class      => 'ManocDB::IPNetwork',
    form_class => 'Manoc::Form::IPNetwork',
);

=head1 METHODS

=cut

before 'view' => sub {
    my ( $self, $c ) = @_;

    my $network = $c->stash->{object};
    my $max_hosts = $network->network->num_hosts;

    my $query_time = time - 60 * 24 * 3600;
    my $arp_60days = $network->arp_entries->search(
        {lastseen => { '>=' => $query_time }},
        {
            columns => [ qw/ipaddr/ ],
            distinct => 1
        })->count();

    
    
    $c->stash(arp_usage => int($arp_60days / $max_hosts * 100 ));

    my $hosts = $network->ip_entries;
    $c->stash(hosts_usage => int( $hosts->count() / $max_hosts * 100));
};

sub get_object_list {
   my ( $self, $c ) = @_;

   my $rs = $c->stash->{resultset};
   return [
       $rs->search(
           {},
           {
               prefetch => 'vlan',
               order_by => { -asc => 'address' }
           } )
   ];
};


sub root : Chained('base') {
    my ( $self, $c ) = @_;
    
    my $rs = $c->stash->{resultset};

    my $n_roots = $rs->get_root_networks->count();
    if ($n_roots == 1) {
        my $root = $rs->get_root_networks->first;

        $c->stash(root_network => $root);
        $rs = $root->children;
    } else {
        $rs = $rs->get_root_networks;
    }

    my @networks = $rs->search(
        {},
        {
            prefetch => [ 'vlan', 'children' ],
            order_by => [
                { -asc  =>  'me.address'        },
                { -desc => 'me.broadcast'       },
                { -asc  => 'children.address'   },
                { -desc => 'children.broadcast' },
            ]
        });
    $c->stash( networks => \@networks);
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
