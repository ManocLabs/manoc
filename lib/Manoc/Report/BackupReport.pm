# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Report::BackupReport;
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

has 'created' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        add_created   => 'push',
        map_created   => 'map',
        created_count => 'count',
        all_created   => 'elements',
    },
);

has 'updated' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        add_updated   => 'push',
        map_updated   => 'map',
        updated_count => 'count',
        all_updated   => 'elements',
    },
);

has 'up_to_date' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        add_up_to_date   => 'push',
        map_up_to_date   => 'map',
        up_to_date_count => 'count',
        all_up_to_date   => 'elements',
    },
);

has 'not_updated' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        add_not_updated   => 'push',
        map_not_updated   => 'map',
        not_updated_count => 'count',
        all_not_updated   => 'elements',
    },
);

no Moose;    # Clean up the namespace.
__PACKAGE__->meta->make_immutable();
1;
