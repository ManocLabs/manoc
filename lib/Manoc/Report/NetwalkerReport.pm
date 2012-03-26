# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Report::NetwalkerReport;
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

has 'visited' => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
);

has 'new_devices' => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
);

has 'cdp_entries' => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
);

has 'mat_entries' => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
);
has 'arp_entries' => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
);


sub update_stats {
 my ($self,$report_stats) = @_;

 foreach my $counter (keys %{$report_stats}){
   if($self->can($counter)){
     $self->$counter($self->$counter + $report_stats->{$counter});
   }
 }
}


1;
