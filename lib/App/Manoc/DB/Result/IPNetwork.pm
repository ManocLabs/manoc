package App::Manoc::DB::Result::IPNetwork;
#ABSTRACT: A model object for IP network addresses

use Moose;

##VERSION

extends 'App::Manoc::DB::Result';

use App::Manoc::IPAddress::IPv4Network;

__PACKAGE__->load_components(
    qw/
        Tree::AdjacencyList
        +App::Manoc::DB::InflateColumn::IPv4
        /
);

__PACKAGE__->table('ip_network');
__PACKAGE__->resultset_class('App::Manoc::DB::ResultSet::IPNetwork');

__PACKAGE__->add_columns(
    'id' => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    'parent_id' => {
        data_type   => 'int',
        is_nullable => 1,
    },
    'name' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64,
    },
    'address' => {
        data_type    => 'varchar',
        is_nullable  => 0,
        size         => 15,
        ipv4_address => 1,
        accessor     => '_address',
    },
    'prefix' => {
        data_type   => 'int',
        is_nullable => 0,
        accessor    => '_prefix',
    },
    'broadcast' => {
        data_type    => 'varchar',
        size         => '15',
        is_nullable  => 0,
        ipv4_address => 1,
        accessor     => '_broadcast',
    },
    'description' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 255
    },
    'vlan_id' => {
        data_type      => 'int',
        is_nullable    => 1,
        is_foreign_key => 1,
    },
    'default_gw' => {
        data_type    => 'varchar',
        is_nullable  => 1,
        size         => 15,
        ipv4_address => 1,
    },

    notes => {
        data_type   => 'text',
        is_nullable => 1,
    },
);

has network => (
    is      => 'rw',
    isa     => 'App::Manoc::IPAddress::IPv4Network',
    lazy    => 1,
    builder => '_build_network',
    trigger => \&_on_set_network,
);

# network attribute builder
sub _build_network {
    my $self = shift;
    defined( $self->address ) or return;
    defined( $self->prefix )  or return;
    App::Manoc::IPAddress::IPv4Network->new( $self->address, $self->prefix );
}

# triggered by network attribute
sub _on_set_network {
    my ( $self, $network, $old_network ) = @_;

    $self->_address( $network->address );
    $self->_prefix( $network->prefix );
    $self->_broadcast( $network->broadcast );
}

=method address

Set/get network address

=cut

sub address {
    my ( $self, $value ) = @_;

    if ( @_ > 1 ) {
        defined( $self->prefix ) and
            $self->network( App::Manoc::IPAddress::IPv4Network->new( $value, $self->prefix ) );
        $self->_address($value);
    }
    return $self->_address();
}

=method prefix

Set/get network prefix

=cut

sub prefix {
    my ( $self, $value ) = @_;

    if ( @_ > 1 ) {

        ( $value >= 0 && $value <= 32 ) or
            die "Bad prefix value $value";

        defined( $self->address ) and
            $self->network( App::Manoc::IPAddress::IPv4Network->new( $self->address, $value ) );
        $self->_prefix($value);
    }
    return $self->_prefix();
}

=method broadcast

Get network broadcast address

=cut

sub broadcast {
    my $self = shift;

    if ( @_ > 1 ) {
        die "The broadcast attribute is automatically set from address and prefix";
    }
    return $self->_broadcast if defined( $self->_broadcast );
    return $self->_broadcast( $self->network->broadcast );
}

=method label

Return a string describing the object

=cut

sub label {
    my $self = shift;
    return $self->name . " (" . $self->network . ")";
}

sub _find_and_update_parent {
    my $self = shift;

    my $supernets = $self->result_source->resultset->search(
        {
            address   => { '<=' => $self->address->padded },
            broadcast => { '>=' => $self->broadcast->padded },
        },
        {
            order_by => [ { -desc => 'me.address' }, { -asc => 'me.broadcast' } ]
        }
    );
    my $parent = $supernets->first();

    # this will bypass dbic::tree
    $parent and $self->_parent($parent);

    return $parent;
}

# call this method after resizing a network
sub _rebuild_subtree {
    my $self = shift;

    if ( $self->children ) {
        my $outside = $self->children->search(
            [
                { address   => { '<' => $self->address->padded } },
                { broadcast => { '>' => $self->broadcast->padded } },
            ]
        );
        while ( my $child = $outside->next() ) {
            $child->parent( $self->parent );
        }
    }

    if ( $self->siblings ) {
        my $outside = $self->siblings->search(
            {
                address   => { '>=' => $self->address->padded },
                broadcast => { '<=' => $self->broadcast->padded }
            }
        );
        while ( my $child = $outside->next() ) {
            $child->parent($self);
        }
    }
}

=for Pod::Coverage

=cut

sub new {
    my ( $self, @args ) = @_;
    my $attrs = shift @args;

    if ( my $network = delete $attrs->{network} ) {
        $attrs->{address}   = $network->address;
        $attrs->{prefix}    = $network->prefix;
        $attrs->{broadcast} = $network->broadcast;
    }

    return $self->next::method( $attrs, @args );
}

=for Pod::Coverage

=cut

sub insert {
    my $self = shift;

    my $parent = $self->_find_and_update_parent();

    $self->next::method(@_);

    my $new_children;
    if ($parent) {
        $new_children = $self->siblings->search(
            {
                address   => { '>=' => $self->address->padded },
                broadcast => { '<=' => $self->broadcast->padded }
            }
        );
    }
    else {
        $new_children = $self->result_source->resultset->search(
            {
                parent_id => { '='  => undef },
                id        => { '!=' => $self->id },
                address   => { '>=' => $self->address->padded },
                broadcast => { '<=' => $self->broadcast->padded }
            }
        );
    }
    while ( my $child = $new_children->next() ) {
        $child->parent($self);
    }

    return $self;
}

=method is_outside_parent

Check if the network is not contained in its parent

=cut

sub is_outside_parent {
    my $self = shift;

    $self->parent or return;
    return $self->address < $self->parent->address ||
        $self->broadcast > $self->parent->broadcast;
}

=method is_inside_children

Check if there is the network is contain in of its  children

=cut

sub is_inside_children {
    my $self = shift;

    $self->children or return;
    return $self->children->search(
        [
            { address   => { '<=' => $self->address->padded } },
            { broadcast => { '>=' => $self->broadcast->padded } },
        ]
    )->count() > 1;
}

=for Pod::Coverage

=cut

sub update {
    my $self = shift;

    my %dirty = $self->get_dirty_columns;

    my $has_changed_size = $dirty{address} || $dirty{broadcast};

    if ($has_changed_size) {
        # check if larger than parent
        $self->is_outside_parent and
            die "network cannot be larger than its parent";

        $self->is_inside_children and
            die "network cannot be smaller than its children";

        $self->_rebuild_subtree();
    }
    $self->next::method(@_);

    if ( !$self->parent && $has_changed_size ) {
        my $new_parent = $self->_find_and_update_parent();
        $new_parent and $self->result_source->resultset->rebuild_tree;
    }

    return $self;
}

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( ['name'] );
__PACKAGE__->add_unique_constraint( [ 'prefix', 'address' ] );

__PACKAGE__->parent_column('parent_id');

__PACKAGE__->belongs_to(
    vlan => 'App::Manoc::DB::Result::Vlan',
    'vlan_id',
    { join_type => 'LEFT' }
);

__PACKAGE__->has_many(
    dhcp_subnets => 'App::Manoc::DB::Result::DHCPSubnet',
    { 'foreign.network_id' => 'self.id' },
);

__PACKAGE__->add_relationship(
    'supernets' => 'IPNetwork',
    sub {
        my $args = shift;

        return {
            "$args->{foreign_alias}.address" => {
                '<=' => { -ident => "$args->{self_alias}.address" },
            },
            "$args->{foreign_alias}.broadcast" => {
                '>=' => { -ident => "$args->{self_alias}.broadcast" },
            },
            "$args->{foreign_alias}.id" => {
                '<>' => { -ident => "$args->{self_alias}.id" }
            }
        };
    },
    {
        order_by => { -asc => [ 'me.address', 'me.broadcast' ] },
    }
);

__PACKAGE__->add_relationship(
    'subnets' => 'IPNetwork',
    sub {
        my $args = shift;

        return {
            "$args->{foreign_alias}.address" => {
                '>=' => { -ident => "$args->{self_alias}.address" },
            },
            "$args->{foreign_alias}.broadcast" => {
                '<=' => { -ident => "$args->{self_alias}.broadcast" },
            },
            "$args->{foreign_alias}.id" => {
                '<>' => { -ident => "$args->{self_alias}.id" }
            }
        };
    }
);

=method arp_entries

Return a resultset for all entries in Arp with IP addresses in this network

=cut

sub arp_entries {
    my $self = shift;

    my $rs = $self->result_source->schema->resultset('Arp');
    $rs = $rs->search(
        {
            'ipaddr' => {
                -between => [ $self->address->padded, $self->broadcast->padded ]
            }
        }
    );

    return $rs;
}

=method ip_entries

Return a resultset for all entries IP contained in this network

=cut

sub ip_entries {
    my $self = shift;

    my $rs = $self->result_source->schema->resultset('Ip');
    $rs = $rs->search(
        {
            'ipaddr' => {
                -between => [ $self->address->padded, $self->broadcast->padded ]
            }
        }
    );
    return wantarray ? $rs->all : $rs;
}

=method ipblock_entries

Return a resultset for all IPBlock entries contained in this network

=cut

sub ipblock_entries {
    my $self = shift;

    my $rs = $self->result_source->schema->resultset('IPBlock');
    $rs = $rs->search(
        {
            'from_addr' => { '>=' => $self->address->padded },
            'to_addr'   => { '<=' => $self->broadcast->padded }
        }
    );

    return wantarray ? $rs->all : $rs;
}

=method supernets

Contain all supernets of this network.

=cut

sub supernets {
    my $self = shift;
    my $rs   = $self->search_related('supernets');
    return wantarray ? $rs->all : $rs;
}

=method supernets_ordered

supernets ordered by address

=cut

sub supernets_ordered {
    my $self = shift;
    my $rs   = $self->supernets->search(
        {},
        {
            order_by => [ { -asc => 'me.address' }, { -desc => 'me.broadcast' } ]
        }
    );
    return wantarray ? $rs->all : $rs;
}

=method subnets

Contain all subnets of this network.

=cut

sub subnets {
    my $self = shift;
    my $rs   = $self->search_related('subnets');
    return wantarray ? $rs->all : $rs;
}

=method first_supernet

=cut

sub first_supernet {
    my $self = shift;
    $self->supernets->first();
}

=method children_ordered

Return children ordered by ascending network address

=cut

sub children_ordered {
    my $self = shift;
    my $rs = $self->children->search( {}, { order_by => { -asc => 'address' } } );

    return wantarray ? $rs->all : $rs;
}

=for Pod::Coverage sqlt_deploy_hook

=cut

sub sqlt_deploy_hook {
    my ( $self, $sqlt_table ) = @_;

    $sqlt_table->add_index(
        name   => 'idx_ipnet_address_broadcast',
        fields => [ 'address', 'broadcast' ]
    );
    $sqlt_table->add_index(
        name   => 'idx_ipnet_address_prefix',
        fields => [ 'address', 'prefix' ]
    );
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
