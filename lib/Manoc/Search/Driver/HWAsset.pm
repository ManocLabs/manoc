# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Driver::HWAsset;
use Moose;
use Manoc::Search::Item::HWAsset;

extends 'Manoc::Search::Driver';

sub search_inventory {
    my ( $self, $query, $result ) = @_;
    my $schema  = $self->engine->schema;
    my $pattern = $query->sql_pattern;

    foreach my $col (qw (serial inventory)) {
        my $rs = $schema->resultset('HWAsset')
            ->search( { $col => { -like => $pattern } }, { order_by => 'name' } );

        while ( my $e = $rs->next ) {
            my $item = Manoc::Search::Item::HWAsset->new(
                {
                    hwasset => $e,
                    match   => $e->$col,
                }
            );
            $result->add_item($item);
        }
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
