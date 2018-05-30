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
        order_by => { -asc => [ 'vtp_domain', 'vid' ] }
    }
);

=action list

=cut

sub list : Chained('object_list') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    # vtp entry id => vlan object
    my $vtp2vlans = {};

    # search vtp entries with missing or mismatched vlan
    my $vtp_entries = $c->stash->{object_list};

    my $vlan_rs      = $c->model('ManocDB::Vlan');
    my @vlan_entries = $vlan_rs->search(
        {},
        {
            prefetch => 'lan_segment',
        }
    );
    my $vlan_index = {};
    foreach my $vlan (@vlan_entries) {
        $vlan_index->{ $vlan->lan_segment->vtp_domain }->{ $vlan->vid } = $vlan;
    }

    foreach my $vtp (@$vtp_entries) {
        my $vlan = $vlan_index->{ $vtp->vtp_domain }->{ $vtp->vid };
        $vtp2vlans->{ $vtp->id } = $vlan;
    }

    $c->stash( vtp2vlans => $vtp2vlans );
}

=action compare

=cut

sub compare : Chained('base') : PathPart('compare') : Args(0) {
    my ( $self, $c ) = @_;

    my $vtp_rs         = $c->stash->{resultset};
    my $vlan_rs        = $c->model('ManocDB::Vlan');
    my $lan_segment_rs = $c->model('ManocDB::LanSegment');

    my $domain2segment = {};
    foreach my $segment ( $lan_segment_rs->all ) {
        $segment->vtp_domain and
            $domain2segment->{ $segment->vtp_domain } = $segment;
    }

    my $vlan_index = {};

    # search vtp entries with missing or mismatched vlan
    my @vtp_entries = $vtp_rs->all();
    foreach my $vtp (@vtp_entries) {
        my $domain = $vtp->vtp_domain;
        $vlan_index->{$domain}->{ $vtp->vid } = {
            vid         => $vtp->vid,
            vtp_name    => $vtp->name,
            vtp_domain  => $domain,
            lan_segment => $domain2segment->{$domain},
        };
    }

    my @vlan_entries = $vlan_rs->search(
        {},
        {
            prefetch => 'lan_segment',
        }
    );
    foreach my $vlan (@vlan_entries) {
        my $domain = $vlan->lan_segment->vtp_domain;
        $domain ||= $vlan->lan_segment->name . "*";

        my $old_values = $vlan_index->{$domain}->{ $vlan->vid } || {};

        $vlan_index->{$domain}->{ $vlan->vid } = {
            %$old_values,
            vid         => $vlan->vid,
            vlan        => $vlan,
            vtp_domain  => $domain,
            lan_segment => $vlan->lan_segment,
        };
    }

    # sort diff entries by id
    my @items;
    foreach my $domain_values ( values %$vlan_index ) {
        push @items, values %$domain_values;
    }

    $c->stash( items => \@items );
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
