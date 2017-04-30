package App::Manoc::DB::ResultSet::Mat;

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

__PACKAGE__->load_components(
    qw/
        +App::Manoc::DB::Helper::ResultSet::TupleArchive
        /
);

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

1;
