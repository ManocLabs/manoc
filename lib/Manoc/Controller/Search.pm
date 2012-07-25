# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Search;
use strict;
use warnings;

use Data::Dumper;
use Moose;
use namespace::autoclean;
use Manoc::Search::QueryType;

#use Manoc::Utils qw(str2seconds ip2int);

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
    my $advanced_search = $c->request->param('advanced') || 0;
    my $limit           = $c->request->param('limit') || '';
    my $type            = $c->request->param('type');

    my @search_types = (
        [ 'ipaddr',    'IP' ],
        [ 'macaddr',   'MAC' ],
        [ 'inventory', 'Inventory' ],
        [ 'logon',     'Logon' ],
        [ 'note',      'Notes' ],
    );

    my $rdrctd_types = {
        device   => 1,
        rack     => 1,
        building => 1
    };

    if ( $q =~ /\S/ ) {
        $q =~ s/^\s+//o;
        $q =~ s/\s+$//o;

        my %extra_param;
        $limit and $extra_param{limit} = $limit;
        $type  and $extra_param{type}  = $type;

        my $result = $c->search( $c->model('ManocDB'), $q, \%extra_param );
        $c->stash( result => $result );

        my $query = $result->query;
        my $type  = $query->query_type;
        if ( !$advanced_search and $rdrctd_types->{$type} ) {
            foreach my $item ( @{ $result->items } ) {
                my $item2 = $item->items->[0];
                if ( lc( $item2->match ) eq lc( $query->query_as_word ) ) {
                    $c->response->redirect(
                        $c->uri_for_action( "/$type/view", [ $item2->id ] ) );
                    $c->detach();
                }
            }

        }

        #Debug mode
        $c->stash( message => Dumper($result) ) if ( $c->req->param('debug') );
    }

    #prepare plugins variables
    my @paths;
    my @plugin = Manoc::Search->_plugin_types;
    foreach my $type (@plugin){
      push @paths, ucfirst($type)."/render.tt";
      push @search_types, [ $type, ucfirst($type) ];
    }
       
    $c->stash( 'q'             => $q );
    $c->stash( limit           => $limit );
    $c->stash( default_type    => $c->request->param('type') || 'ipaddr' );
    $c->stash( search_types    => \@search_types );
    $c->stash( advanced_search => $advanced_search );
    $c->stash( plugins         => \@paths );

    $c->stash( template => 'search/index.tt' );
}

sub instruction : Path('readme') Args(0) {
    my ( $self, $c ) = @_;
    my $page = $c->request->param('page');
    $c->stash( template => 'search/readme.tt' );

    $c->stash(template => "search/readme/$page.tt") if(defined $page);
}

=head1 AUTHOR

gabriele

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
