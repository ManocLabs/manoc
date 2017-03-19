# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Helper::NetwalkerPoller;
use strict;
use warnings;

sub make_poller_columns {
    my $self = shift;

    $self->add_columns(
        offline => {
            data_type     => 'int',
            size          => 1,
            default_value => '0',
        },
        
        last_visited => {
            data_type     => 'int',
            default_value => '0',
        },
        
        scheduled_attempt => {
            data_type     => 'int',
            default_value => '0',
        },
        
        attempt_backoff => {
            data_type     => 'int',
            default_value => '0',
        },
        
        netwalker_status => {
            data_type     => 'varchar',
            size          => 255,
            default_value => 'NULL',
            is_nullable   => 1,
        },
    );
}

1;
