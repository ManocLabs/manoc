# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Driver::Mat;
use Moose;
extends 'Manoc::Search::Driver';

use Manoc::Search::Item::Iface;
use Manoc::Search::Item::Device;

sub search_macaddr {
    my ( $self, $query, $result ) = @_;

    my $pattern = $query->sql_pattern;
    my $schema  = $self->engine->schema;

    my $search = { macaddr => { like => $pattern } };

    my $options = {
        select =>
            [ 'device', 'macaddr', 'interface', { max => 'lastseen', -as => 'timestamp' } ],
        as       => [ 'device', 'macaddr', 'interface', 'timestamp' ],
        group_by => [qw(device macaddr interface)],
#        join     => { 'device_entry' => 'mng_url_format' },
#        prefetch => { 'device_entry' => 'mng_url_format' },
    };

    $query->limit and
        $options->{having} = { timestamp => { '>' => $query->start_date } };

     my $it = $schema->resultset('Mat')->search( $search, $options );

     while ( my $e = $it->next ) {
         #my $device = Manoc::Search::Item::Device->new( { device => $e->device_entry } );
         my $item = Manoc::Search::Item::Iface->new(
             {
                 match     => $e->macaddr,
                 device    => $e->device_entry,#$device,
                 interface => $e->interface,
                 timestamp => $e->get_column('timestamp'),
             }
         );
         $result->add_item($item);
     }

}

no Moose;
__PACKAGE__->meta->make_immutable;
