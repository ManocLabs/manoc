# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::Arp;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

with 'Manoc::ControllerRole::JQDatatable';

use Manoc::Utils qw/print_timestamp/;

=head1 NAME

Manoc::Controller::Arp - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 list

=cut

sub list : Private {
    my ( $self, $c ) = @_;
    $c->stash(template => 'arp/list.tt');
}

sub list_js : Private {
    my ( $self, $c ) = @_;
    
    my $row_callback = sub {
        my ($ctx, $row) = @_;
        my $address = Manoc::IPAddress::IPv4->new($row->get_column('ip_address'));
        return [
            "$address",
            print_timestamp($row->get_column('firstseen')),
            print_timestamp($row->get_column('lastseen')),
        ]
    };

    $c->stash(
        datatable_row_callback   => $row_callback,
        datatable_search_columns => [ qw/ipaddr/ ],
        datatable_columns        => [ qw/ipaddr firstseen lastseen/],
    );

    $c->detach('datatable_response');
}


=encoding utf8

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
