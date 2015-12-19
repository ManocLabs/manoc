# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::VlanRange;

use parent 'DBIx::Class::Core';

use strict;
use warnings;
use Carp;

__PACKAGE__->load_components(qw/+Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('vlan_range');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0
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
__PACKAGE__->has_many( vlans => 'Manoc::DB::Result::Vlan', 'vlan_range' );

__PACKAGE__->resultset_class('Manoc::DB::ResultSet::VlanRange');

sub get_mergeable_ranges {
    my ( $self, $options ) = @_;

    my $rs = $self->result_source->resultset;
    return $rs->search( [ { start => $self->end + 1 }, { end => $self->start - 1 }, ],
        $options );
}

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
                        name  => $name,
                        start => $split_point,
                        end   => $self->end,
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
                        name  => $name,
                        start => $self->start,
                        end   => $split_point - 1,
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

=head1 NAME

Manoc::DB::Result::Vlan - A model object representing the table vlan_range

=head1 DESCRIPTION

This is an object that represents a row in the 'vlan_range' table of your
application database.  It uses DBIx::Class (aka, DBIC) to do ORM.

=cut

1;
