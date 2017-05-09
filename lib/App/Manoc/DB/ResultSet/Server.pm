package App::Manoc::DB::ResultSet::Server;
#ABSTRACT: ResultSet class for Server

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

=method hypervisors

Resultset for non decommisioned hypervisors.

=cut

sub hypervisors {
    my $self = shift;

    my $rs = $self->search( { is_hypervisor => 1, decommissioned => 0 } );
    return wantarray ? $rs->all : $rs;
}

=method standalone_hypervisors

Resultset for non standalone hypervisors.

=cut

sub standalone_hypervisors {
    my $self = shift;

    my $rs = $self->hypervisors->search( { virtual_infr => undef } );
    return wantarray ? $rs->all : $rs;
}

=method logical_servers

Resultset for non logical servers (no virtualmachine or hardware associated).

=cut

sub logical_servers {
    my $self = shift;

    my $rs = $self->search( { vm_id => undef, serverhw_id => undef }, );
    return wantarray ? $rs->all : $rs;
}

=head1 SEE ALSO

L<DBIx::Class::ResultSet>

=cut

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
