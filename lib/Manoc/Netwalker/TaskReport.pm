# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Netwalker::TaskReport;

use Moose;
use MooseX::Storage;

our $VERSION = '0.01';

with Storage( 'format' => 'YAML' );

has 'warning' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        add_warning   => 'push',
        map_warning   => 'map',
        warning_count => 'count',
        all_warning   => 'elements',
    },
);

has 'error' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        add_error   => 'push',
        map_error   => 'map',
        error_count => 'count',
        has_error   => 'count',
        all_errors  => 'elements',
    },
);

has 'host' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'visited' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has 'new_devices' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has 'cdp_entries' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has 'mat_entries' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has 'arp_entries' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

1;
