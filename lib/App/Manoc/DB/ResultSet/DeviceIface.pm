package App::Manoc::DB::ResultSet::DeviceIface;
#ABSTRACT: ResultSet class for IfNotes
use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

use App::Manoc::DB::Search::Result::Iface;

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

=method search_uncabled(  $device )

Return a resultset containing all interfaces of <$device> which are not in
the cabling matrix

=cut

sub search_uncabled {
    my ( $self, $device ) = @_;

    my $conditions = { 'cabling.interface2_id' => undef };
    $device and $conditions->{'me.device_id'} = $device;

    my $rs = $self->search(
        $conditions,
        {
            alias => 'me',
            join  => 'cabling',
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
            group_by => [qw(me.device_id me.name)],
            select   => [ 'me.name', { max => 'mat_entry.lastseen' }, ],
            as       => [qw(interface lastseen)],
            join     => 'mat_entry',
        }
    );
    return wantarray ? $rs->all : $rs;
}

=method manoc_search(  $query, $result)

Support for Manoc search feature

=cut

sub manoc_search {
    my ( $self, $query, $result ) = @_;

    my $type    = $query->query_type;
    my $pattern = $query->sql_pattern;

    return unless $type eq 'notes';

    my $filter;
    $type eq 'notes' and $filter = { notes => { '-like' => $pattern } };

    my $rs = $self->search(
        $filter,
        {
            order_by => '',
            prefetch => 'device',
        },
    );
    while ( my $e = $rs->next ) {
        my $item = App::Manoc::DB::Search::Result::Iface->new(
            {
                device    => $e->device,
                interface => $e->interface,
                text      => $e->description,
            }
        );
        $result->add_item($item);
    }
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
