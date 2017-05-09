package App::Manoc::DB::ResultSet::IfStatus;
#ABSTRACT: ResultSet class for IfStatus
use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

=method search_unused(  $device )

Return a resultset containing all interfaces of <$device> which were never seen in
mac address table.

=cut

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

=method search_mat_last_activity (  $device )

Return a resultset containing all interfaces of <$device> with their corresponding
maximum value of lastseen in Mat.

=cut

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
