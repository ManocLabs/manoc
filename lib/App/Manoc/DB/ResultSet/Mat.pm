package App::Manoc::DB::ResultSet::Mat;
#ABSTRACT: ResultSet class for Mat

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

__PACKAGE__->load_components(
    qw/
        +App::Manoc::DB::Helper::ResultSet::TupleArchive
        /
);

=method search_multihost

Return a resultset containing interfaces on which has been activity for more
than one mac address. Returned columns are device (containing device id),
interface, count and description.

=cut

sub search_multihost {
    my $self = shift;

    my $rs = $self->search(
        { 'archived' => 0 },
        {
            select => [
                'me.device_id', 'me.interface',
                { count => { distinct => 'macaddr' } }, 'description',
            ],

            as       => [ 'device', 'interface', 'count', 'description', ],
            group_by => [ 'device', 'interface' ],
            having => { 'COUNT(DISTINCT(macaddr))' => { '>', 1 } },
            order_by => [ 'me.device_id', 'me.interface' ],
            alias    => 'me',
            from     => [
                { me => 'mat' },
                [
                    { 'ifstatus' => 'if_status' },
                    {
                        'ifstatus.device_id' => 'me.device_id',
                        'ifstatus.interface' => 'me.interface',
                    }
                ]
            ]
        }
    );
    return wantarray ? $rs->all : $rs;
}

=method manoc_search(  $query, $result)

Support for Manoc search feature

=cut

sub manoc_search {

    my ( $self, $query, $result ) = @_;

    my $type = $query->query_type;
    $type eq 'macaddr' or return;

    my $pattern = $query->sql_pattern;

    my $search = { macaddr => { like => $pattern } };

    my $options = {
        select =>
            [ 'device_id', 'macaddr', 'interface', { max => 'lastseen', -as => 'timestamp' } ],
        as       => [ 'device_id', 'macaddr', 'interface', 'timestamp' ],
        group_by => [qw(device_id macaddr interface)],
        #        join     => { 'device_entry' => 'mng_url_format' },
        #        prefetch => { 'device_entry' => 'mng_url_format' },
    };

    $query->limit and
        $options->{having} = { timestamp => { '>' => $query->start_date } };

    my $rs = $self->search( $search, $options );
    while ( my $e = $rs->next ) {
        my $item = App::Manoc::DB::Search::Result::Iface->new(
            {
                match     => $e->macaddr,
                device    => $e->device,                    #$device,
                interface => $e->interface,
                timestamp => $e->get_column('timestamp'),
            }
        );
        $result->add_item($item);
    }
}
1;
