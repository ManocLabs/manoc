# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::ResultSet::Mat;

use strict;
use warnings;

use parent 'Manoc::DB::ResultSet';

__PACKAGE__->load_components(
    qw/
        +Manoc::DB::Helper::ResultSet::TupleArchive
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
