package App::Manoc::Controller::Arp;
#ABSTRACT: Arp Catalyst Controller

use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }
with
    'App::Manoc::ControllerRole::ResultSet',
    'App::Manoc::ControllerRole::JQDatatable';

use App::Manoc::Utils::Datetime qw/print_timestamp/;

=head1 DESCRIPTION

Catalyst Controller.

=cut

=action list

=cut

sub list : Private {
    my ( $self, $c ) = @_;

    $c->require_permission( 'arp', 'view' );

    $c->stash( template => 'arp/list.tt' );
}

=action list_js

=cut

sub list_js : Private {
    my ( $self, $c ) = @_;

    $c->require_permission( 'arp', 'view' );

    my $row_callback = sub {
        my ( $ctx, $row ) = @_;
        my $address = App::Manoc::IPAddress::IPv4->new( $row->get_column('ip_address') );
        return [
            "$address",
            print_timestamp( $row->get_column('firstseen') ),
            print_timestamp( $row->get_column('lastseen') ),
        ];
    };

    $c->stash(
        datatable_row_callback   => $row_callback,
        datatable_search_columns => [qw/ipaddr/],
        datatable_columns        => [qw/ipaddr firstseen lastseen/],
    );

    $c->detach('datatable_response');
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
