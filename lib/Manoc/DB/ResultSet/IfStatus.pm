# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::ResultSet::IfStatus;

use strict;
use warnings;

use parent 'Manoc::DB::ResultSet';

sub search_unused {
    my ( $self, $device ) = @_;

    my $conditions = { 'mat_entry.macaddr' => undef };
    $device and $conditions->{'me.device_id'} = $device;

    my $rs = $self->search(
        $conditions,
        {
            alias => 'me',
            join  => 'mat_entry',
        }
    );
    return wantarray ? $rs->all : $rs;
}

sub search_mat_last_activity {
    my ( $self, $device ) = @_;

    my $conditions = {};
    $device and $conditions->{'me.device_id'} = $device;

    my $rs = $self->search(
        $conditions,
        {
            alias    => 'me',
            group_by => [qw(me.device_id me.interface)],
            select   => [ 'me.interface', { max => 'mat_entry.lastseen' }, ],
            as       => [qw(interface lastseen)],
            join     => 'mat_entry',
        }
    );
    return wantarray ? $rs->all : $rs;
}
1;
