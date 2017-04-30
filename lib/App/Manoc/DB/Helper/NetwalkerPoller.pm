package App::Manoc::DB::Helper::NetwalkerPoller;

use strict;
use warnings;

##VERSION

use parent 'DBIx::Class';

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
