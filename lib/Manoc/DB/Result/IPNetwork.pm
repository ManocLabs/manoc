# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::IPNetwork;

use Moose;

#  'extends' since we are using Moose
extends 'DBIx::Class::Core';

use Manoc::IPAddress::IPv4Network;

__PACKAGE__->load_components(
    qw/Tree::AdjacencyList +Manoc::DB::InflateColumn::IPv4/
);

__PACKAGE__->table('ip_network');
__PACKAGE__->resultset_class('Manoc::DB::ResultSet::IPNetwork');

__PACKAGE__->add_columns(
    'id' => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    'parent_id' => {
        data_type         => 'int',
        is_nullable       => 1,
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
        data_type    => 'int',
        is_nullable  => 0,
        accessor     => '_prefix',
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
    }
);

has network => (
    is   => 'rw',
    isa  => 'Manoc::IPAddress::IPv4Network',
    lazy => 1,
    builder => 'build_network',
    trigger => \&on_set_network,
);

sub build_network {
    my $self = shift;
    defined ($self->address) or return;
    defined ($self->prefix)  or return;
    Manoc::IPAddress::IPv4Network->new($self->address, $self->prefix);
}

sub on_set_network {
    my ( $self, $network, $old_network ) = @_;

    $self->_address($network->address);
    $self->_prefix($network->prefix);
    $self->_broadcast($network->broadcast);
}

sub address {
    my ($self, $value) = @_;

    if (@_ > 1) {
        defined($self->prefix) and
            $self->network(Manoc::IPAddress::IPv4Network->new($value, $self->prefix));
        $self->_address($value);
    }
    return $self->_address();
}

sub prefix {
    my ($self, $value) = @_;

    if (@_ > 1) {

        ($value >= 0 && $value <= 32)
            or die "Bad prefix value $value";

        defined($self->address) and
            $self->network( Manoc::IPAddress::IPv4Network->new($self->address, $value) );
        $self->_prefix($value);
    }
    return $self->_prefix();
}

sub broadcast {
    my $self = shift;
    
    if (@_ > 1) {
        die "The broadcast attribute is automatically set from address and prefix";
    }
    return $self->_broadcast;
}

# call this method after resizing a network
sub _rebuild_subtree {
    my $self = shift;

    warn "build subtree";
    if ($self->children) {
        my $outside = $self->children->search(
            [
                { address   => { '<' => $self->address->padded   } },
                { broadcast => { '>' => $self->broadcast->padded } },
            ]);
        while ( my $child = $outside->next()) {
            $child->parent($self->parent);
        }
    }
    
    if ($self->siblings) {
        my $outside = $self->siblings->search(
            {
                address   => { '>=' => $self->address->padded   },
                broadcast => { '<=' => $self->broadcast->padded }
            });
        while ( my $child = $outside->next()) {
            $child->parent($self);
        }
    }
}

sub insert {
    my $self = shift;

    if ( ! defined( $self->parent )) {
        my $supernets = $self->result_source->resultset->search(
            {
                address  =>  { '<=' => $self->address->padded   },
                broadcast => { '<=' => $self->broadcast->padded },
            },
            {
                order_by => [
                    { -asc => 'me.address' },
                    { -desc => 'me.broadcast' }
                ]
            });
        #bypass dbic::tree
        $self->_parent( $supernets->first() );
    }
    $self->next::method( @_ );
}

sub update {
    my $self = shift;

    my %dirty = $self->get_dirty_columns;

    if ( $dirty{address} || $dirty{broadcast} ) {
        if ($self->parent && (
            ( $self->address < $self->parent->address ||
                  $self->broadcast > $self->parent->broadcast) ))
            {
                die "network cannot be larger than its parent"
            }
        $self->_rebuild_subtree();
    }
    $self->next::method( @_ );
}

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [ 'name' ] );
__PACKAGE__->add_unique_constraint( [ 'prefix', 'address' ] );

__PACKAGE__->parent_column('parent_id');

__PACKAGE__->belongs_to( vlan => 'Manoc::DB::Result::Vlan',
                         'vlan_id',
                         { join_type => 'left' });

__PACKAGE__->add_relationship(
    'supernets' => 'IPNetwork',
    sub {
        my $args = shift;

        return {
            "$args->{foreign_alias}.address"     => {
                '<=' => { -ident => "$args->{self_alias}.address" },
            },
            "$args->{foreign_alias}.broadcast"   => {
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
            "$args->{foreign_alias}.address"     => {
                '>=' => { -ident => "$args->{self_alias}.address" },
            },
            "$args->{foreign_alias}.broadcast"   => {
                '<=' => { -ident => "$args->{self_alias}.broadcast" },
            },
            "$args->{foreign_alias}.id" => {
                '<>' => { -ident => "$args->{self_alias}.id" }
            }
        };
    }
);


sub arp_entries {
    my $self = shift;

    my $rs = $self->result_source->schema->resultset('Arp');
    $rs = $rs->search(
	{
	    'ipaddr' => {
		-between => [ $self->address->padded, $self->broadcast->padded ] }
	});

    return wantarray() ? $rs->all() : $rs;
}

sub ip_entries {
    my $self = shift;

    my $rs = $self->result_source->schema->resultset('Ip');
    $rs = $rs->search(
	{
	    'ipaddr' => {
		-between => [ $self->address->padded, $self->broadcast->padded ] }
	});
    return wantarray() ? $rs->all() : $rs;
}

sub supernets {
    my $self = shift;
    my $rs = $self->search_related('supernets');
    return wantarray() ? $rs->all : $rs;
}


sub supernets_ordered {
    my $self = shift;
    my $rs = $self->supernets->search(
        {},
        {
            order_by => [
                { -asc => 'me.address' },
                { -desc => 'me.broadcast' }
            ]
        });

    return wantarray ? $rs->all : $rs;
}

sub subnets {
    my $self = shift;
    my $rs = $self->search_related('subnets');
    return wantarray() ? $rs->all : $rs;
}

sub first_supernet {
    my $self = shift;
    $self->supernets->first();
}

sub children_ordered {
    my $self = shift;
    my $rs = $self->children->search({}, { order_by => { -asc => 'address' }});

    return wantarray ? $rs->all : $rs;
}


sub sqlt_deploy_hook {
   my ($self, $sqlt_table) = @_;

   $sqlt_table->add_index(name => 'idx_address_broadcast', fields => ['address', 'broadcast']);
   $sqlt_table->add_index(name => 'idx_address_prefix', fields => ['address', 'prefix']);
}


1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
