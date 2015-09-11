# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Search;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

use Manoc::Search::QueryType;
use Manoc::Search::Engine;
use Manoc::Search::Query;
use Manoc::Utils qw(str2seconds);

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Manoc::Controller::Search - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    my $q               = $c->request->param('q') || '';
    my $button          = $c->request->param('submit');
    my $advanced        = $c->request->param('advanced') || 0;
    my $limit           = $c->request->param('limit') || '';
    my $type            = $c->request->param('type');

    my @search_types = (
        [ 'ipaddr',    'IP' ],
        [ 'macaddr',   'MAC' ],
        [ 'inventory', 'Inventory' ],
        [ 'logon',     'Logon' ],
        [ 'note',      'Notes' ],
    );

    my $redirectable_types = {
        device   => '/device/view',
        rack     => '/rack/view',
        building => '/building/view',
    };

    if ( $q =~ /\S/ ) {
        $q =~ s/^\s+//o;
        $q =~ s/\s+$//o;

        my %query_param;
        $limit and $query_param{limit} = str2seconds($limit);
        $type  and $query_param{type}  = $type;

        my $result = $c->model('ManocDB')->search($q, \%query_param );
        $c->stash( result => $result );

        my $query = $result->query;
        my $type  = $query->query_type;

        if ( !$advanced && $redirectable_types->{$type} ) {
	    # search for an exact match and redirect
            foreach my $item ( @{ $result->items } ) {
                my $item2 = $item->items->[0];
                if ( lc( $item2->match ) eq lc( $query->query_as_word ) ) {
                    $c->response->redirect(
                        $c->uri_for_action( $redirectable_types->{$type},
					    [ $item2->id ] ));
		    $c->detach();
		}
            }
        }

	$result->load_widgets;
    }

    $c->stash( fif => {
	'q'       => $q,
	limit     => $limit,
	type      => $c->request->param('type') || 'ipaddr',
	advanced  => $advanced,
    });
    $c->stash( search_types    => \@search_types );
}

sub _plugin_types {
  my ($self, $c) = shift;

  return unless $self->can('plugin_registry');
  # my $reg = $self->plugin_registry;
  # foreach my $plugin TODO
  return
}


=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
