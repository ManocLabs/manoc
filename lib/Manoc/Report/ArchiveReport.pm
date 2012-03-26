
# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Report::ArchiveReport;
use Moose;
use MooseX::Storage;

our $VERSION = '0.01';

extends 'Manoc::Report';

has 'error' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        add_error   => 'push',
        map_error   => 'map',
        error_count => 'count',
        all_error   => 'elements',
    },
);

has 'tot_archived' => (
    is  => 'rw',
    isa => 'Int',
);

has 'tot_discarded' => (
    is  => 'rw',
    isa => 'Int',
);

has 'archived' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        add_archived   => 'push',
        map_archived   => 'map',
        error_archived => 'count',
        all_archived   => 'elements',
    },
);

has 'discarded' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        add_discarded   => 'push',
        map_discarded   => 'map',
        discarded_count => 'count',
        all_discarded   => 'elements',
    },
);

has 'discard_date' => (
    is  => 'rw',
    isa => 'Str',
);

has 'archive_date' => (
    is  => 'rw',
    isa => 'Str',
);

has 'reports_date' => (
    is  => 'rw',
    isa => 'Str',
);

1;
