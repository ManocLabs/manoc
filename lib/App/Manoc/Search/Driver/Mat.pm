package App::Manoc::Search::Driver::Mat;

use Moose;

##VERSION

extends 'App::Manoc::Search::Driver';

use App::Manoc::Search::Item::Iface;
use App::Manoc::Search::Item::Device;

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
        #my $device = App::Manoc::Search::Item::Device->new( { device => $e->device_entry } );
        my $item = App::Manoc::Search::Item::Iface->new(
            {
                match     => $e->macaddr,
                device    => $e->device_entry,              #$device,
                interface => $e->interface,
                timestamp => $e->get_column('timestamp'),
            }
        );
        $result->add_item($item);
    }

}

no Moose;
__PACKAGE__->meta->make_immutable;
