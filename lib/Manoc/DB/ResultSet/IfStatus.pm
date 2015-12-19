# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::ResultSet::IfStatus;

use base 'DBIx::Class::ResultSet';
use strict;
use warnings;

sub search_unused {
    my ( $self, $device ) = @_;

    my $conditions = { 'mat_entry.macaddr' => undef };
    $device and $conditions->{'me.device'} = $device;

    $self->search(
        $conditions,
        {
            alias => 'me',
            join  => 'mat_entry',
        }
    );
}

sub search_mat_last_activity {
    my ( $self, $device ) = @_;

    my $conditions = {};
    $device and $conditions->{'me.device'} = $device;

    $self->search(
        $conditions,
        {
            alias    => 'me',
            group_by => [qw(me.device me.interface)],
            select   => [ 'me.interface', { max => 'mat_entry.lastseen' }, ],
            as       => [qw(interface lastseen)],
            join     => 'mat_entry',
        }
    );
}
1;
