package App::Manoc::Controller::VTP;
#ABSTRACT: VTP controller

use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

with
    'App::Manoc::ControllerRole::ResultSet',
    'App::Manoc::ControllerRole::ObjectList';

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'vtp',
        }
    },
    class               => 'ManocDB::VlanVtp',
    view_object_perm    => undef,
    object_list_options => {
        prefetch => 'vlan'
    }
);

=action list

=cut

sub list : Chained('object_list') : PathPart('') : Args(0) {
    # just use defaults
}

=action compare

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

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
