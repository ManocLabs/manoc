# Copyright 2011-2016 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::ResultSet::Server;

use base 'DBIx::Class::ResultSet';
use strict;
use warnings;

sub hypervisors {
    my $self = shift;

    my $rs = $self->search( { is_hypervisor => 1, decommissioned => 0 } );
    return wantarray() ? $rs->all() : $rs;
}

sub standalone_hypervisors {
    my $self = shift;

    my $rs = $self->hypervisors->search( { virtual_infr => undef } );
    return wantarray() ? $rs->all() : $rs;
}

sub logical_servers {
    my $self = shift;

    my $rs = $self->search( { vm_id => undef, serverhw_id => undef }, );
    return wantarray() ? $rs->all() : $rs;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
