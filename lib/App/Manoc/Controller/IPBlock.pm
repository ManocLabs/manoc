package App::Manoc::Controller::IPBlock;
#ABSTRACT: IPBlock controller
use Moose;

##VERSION

use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }

with 'App::Manoc::ControllerRole::CommonCRUD';

use App::Manoc::Form::IPBlock;
use App::Manoc::Utils::Datetime qw(str2seconds);

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'ipblock',
        }
    },
    class            => 'ManocDB::IPBlock',
    form_class       => 'App::Manoc::Form::IPBlock',
    view_object_perm => undef,
    json_columns     => [qw( id name from_addr to_addr )],
);

=action view

Override in order to add ARP statistics.

=cut

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

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
