package App::Manoc::Controller::Vlan;
#ABSTRACT: Vlan controller

use Moose;

##VERSION

use namespace::autoclean;
use App::Manoc::Form::Vlan;

BEGIN { extends 'App::Manoc::ControllerBase::CRUD'; }

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'vlan',
        }
    },
    class               => 'ManocDB::Vlan',
    form_class          => 'App::Manoc::Form::Vlan',
    json_columns        => [ 'id', 'name', 'description' ],
    view_object_perm    => undef,
    object_list_options => {
        prefetch => 'vlan_range',
        order_by => { -asc => [ 'me.lan_segment_id', 'vid' ] }
    }
);

=action  vid

View Vlan by vid

=cut

sub vid : Chained('base') : PathPart('vid') : Args(1) {
    my ( $self, $c, $vid ) = @_;

    $self->view_object_perm and
        $c->require_permission( $c->stash->{resultset}, $self->view_object_perm );

    my $qp            = $c->req->query_parameters;
    my $segment_param = $qp->{lansegment};

    my $search_params = { vid => $vid };
    if ( defined($segment_param) ) {
        $search_params->{lansegment_id} = $segment_param;
    }

    my $object_list = [ $c->stash->{resultset}->search($search_params)->all ];

    if ( @$object_list == 1 ) {
        my $id = $object_list->[0]->id;
        $c->debug and
            $c->log->debug("Only one vlan found, redirect to vlan/view $id");
        $c->go( '/vlan/view', [$id], [] );
    }

    $c->stash(
        vid         => $vid,
        object_list => $object_list
    );

}

before 'list' => sub {
    my ( $self, $c ) = @_;

    my $segment      = $c->stash->{cur_segment};
    my $segment_list = [
        $c->model('ManocDB::LanSegment')->search(
            {},
            {
                order_by => ['me.name'],
            }
        )->all()
    ];

    my @range_list = $c->model('ManocDB::VlanRange')->search(
        {
            lan_segment_id => $segment->id,
        },
        {
            order_by => { -asc => ['me.start'] },
        }
    )->all();
    my @vlan_list = @{ $c->stash->{object_list} };

    my @mixed_vlan_range_list;
    while ( @vlan_list && @range_list ) {
        if ( $range_list[0]->start <= $vlan_list[0]->vid ) {
            my $range = shift @range_list;
            push @mixed_vlan_range_list, { range => $range };
        }
        else {
            my $vlan = shift @vlan_list;
            push @mixed_vlan_range_list, { vlan => $vlan };
        }
    }
    while ( my $range = shift @range_list ) {
        push @mixed_vlan_range_list, { range => $range };
    }
    while ( my $vlan = shift @vlan_list ) {
        push @mixed_vlan_range_list, { vlan => $vlan };
    }

    $c->stash(
        segment_list          => $segment_list,
        mixed_vlan_range_list => \@mixed_vlan_range_list,
    );

};

=method get_object_list_filter

=cut

override get_object_list_filter => sub {
    my ( $self, $c ) = @_;

    my %filter;

    my $qp = $c->req->query_parameters;

    my $segment;
    if ( my $segment_param = $qp->{lansegment} ) {
        $c->debug and $c->log->debug("looking for segment=$segment_param");
        $segment = $c->model('ManocDB::LanSegment')->find( { id => $segment_param } );
        $c->debug and $c->log->debug( $segment ? "segment found" : "segment not found" );
    }
    if ( !$segment ) {
        $segment =
            $c->model('ManocDB::LanSegment')->search( {}, { order_by => { -asc => ['id'] } } )
            ->first();
        $c->debug and $c->log->debug("Use first segment found");
    }

    $filter{"me.lan_segment_id"} = $segment->id;
    $c->stash( cur_segment => $segment );

    return \%filter;
};

=action create

=cut

before 'create' => sub {
    my ( $self, $c ) = @_;

    my $form_defaults = {};

    my $lan_segment_id = $c->req->query_parameters->{'lansegment'};
    my $lan_segment;
    if ( defined($lan_segment_id) ) {
        $lan_segment = $c->model('ManocDB::LanSegment')->find( { id => $lan_segment_id } );
    }
    else {
        if ( $c->model('ManocDB::LanSegment')->count == 1 ) {
            $lan_segment = $c->model('ManocDB::LanSegment')->single();
        }
    }
    $c->debug and $c->log->debug( $lan_segment ? "segment found" : "segment not foud" );
    $form_defaults->{lan_segment} = $lan_segment;

    my $vid = $c->req->query_parameters->{'vid'};
    $vid and $form_defaults->{vid} = $vid;

    my $name = $c->req->query_parameters->{'name'};
    $name and $form_defaults->{name} = $name;

    $c->stash( form_defaults => $form_defaults );
};

=method object_delete

=cut

sub object_delete {
    my ( $self, $c ) = @_;
    my $vlan = $c->stash->{'object'};

    if ( $vlan->ip_ranges->count ) {
        $c->flash( error_msg => 'There are subnets in this vlan' );
        return;
    }

    $vlan->delete;
}

=method get_form_success_url

=cut

sub get_form_success_url {
    my ( $self, $c ) = @_;

    my $vlan           = $c->stash->{object};
    my $lan_segment_id = $vlan->lan_segment_id;

    return $c->uri_for_action( "vlan/list", { lansegment => $lan_segment_id } );
}

__PACKAGE__->meta->make_immutable;

1;
