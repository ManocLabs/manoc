package App::Manoc::DB::Result::VlanRange;
#ABSTRACT:  A model object representing the table vlan_range
use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

use Carp;

__PACKAGE__->load_components(qw/+App::Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('vlan_range');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0
    },
    lan_segment_id => {
        data_type      => 'int',
        is_nullable    => 0,
        is_foreign_key => 1
    },
    name => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
    },
    start => {
        data_type   => 'int',
        is_nullable => 0,
        extras      => { unsigned => 1 }
    },
    end => {
        data_type   => 'int',
        is_nullable => 0,
        extras      => { unsigned => 1 }
    },
    description => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 1
    }
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( ['name'] );
__PACKAGE__->has_many( vlans => 'App::Manoc::DB::Result::Vlan', 'vlan_range_id' );

__PACKAGE__->resultset_class('App::Manoc::DB::ResultSet::VlanRange');

__PACKAGE__->belongs_to( lan_segment => 'App::Manoc::DB::Result::LanSegment', 'lan_segment_id' );


=method get_mergeable_ranges

Return a resultset containing all ranges which can be merged with this one

=cut

sub get_mergeable_ranges {
    my ( $self, $options ) = @_;

    my $rs = $self->result_source->resultset;
    return $rs->search(
        {
            [ { start => $self->end + 1 }, { end => $self->start - 1 }, ],
            { lan_segment_id => $self->lan_segment_id }
        },
        $options );
    return wantarray ? $rs->all : $rs;

}

=method split_new_range($name, $split_point, $direction)

Creating a new range called $name splitting the current one at id $split_point
in the given $direction. Direction can be "UP" or "DOWN".

=cut

sub split_new_range {
    my ( $self, $name, $split_point, $direction ) = @_;

    $direction = uc($direction);
    $direction eq 'UP' || $direction eq 'DOWN' or
        croak "Unknown value '$direction' for direction parameter";

    unless ( $split_point > $self->start && $split_point < $self->end ) {
        croak "Split point must be inside range";
    }

    #Update DB (with a transaction)
    my $rs     = $self->result_source->resultset;
    my $schema = $self->result_source->schema;

    $schema->txn_do(
        sub {
            if ( $direction eq 'UP' ) {
                # create new range
                my $new_range = $rs->create(
                    {
                        name           => $name,
                        lan_segment_id => $self->lan_segment_id,
                        start          => $split_point,
                        end            => $self->end,
                    }
                );

                # update this object
                $self->end( $split_point - 1 );
                $self->update;

                # update vlans
                foreach my $vlan ( $self->vlans ) {
                    print STDERR "review $vlan\n";
                    if ( $vlan->id >= $split_point ) {
                        $vlan->vlan_range($new_range);
                        $vlan->update;
                    }
                }
            }
            else {    # $direction eq DOWN
                      # create new range
                my $new_range = $rs->create(
                    {
                        name           => $name,
                        lan_segment_id => $self->lan_segment_id,
                        start          => $self->start,
                        end            => $split_point - 1,
                    }
                );

                # update this object
                $self->start($split_point);
                $self->update;

                # update vlans
                foreach my $vlan ( $self->vlans ) {
                    print STDERR "review $vlan\n";
                    if ( $vlan->id < $split_point ) {
                        $vlan->vlan_range($new_range);
                        $vlan->update;
                    }
                }
            }
        }
    );    # end of transaction
}

=method merge_with_range( $other )

Merge the range with an adjancent $other.

=cut

sub merge_with_range {
    my ( $self, $other ) = @_;

    if ( $other->start != $self->end + 1 &&
        $other->end + 1 != $self->start )
    {
        croak "VlanRanges cannot be merged";
    }

    #Update DB (with a transaction)
    my $rs     = $self->result_source->resultset;
    my $schema = $self->result_source->schema;

    $schema->txn_do(
        sub {
            if ( $other->start == $self->end + 1 ) {
                $self->end( $other->end );
            }
            elsif ( $other->end + 1 == $self->start ) {
                $self->start( $other->start );
            }
            else {
                croak "This should not happen!!";
            }

            foreach my $vlan ( $other->vlans ) {
                $vlan->vlan_range($self);
                $vlan->update;
            }
            $other->delete;
        }
    );
}

1;
