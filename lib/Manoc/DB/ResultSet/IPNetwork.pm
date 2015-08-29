# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::ResultSet::IPNetwork;

use base 'DBIx::Class::ResultSet';
use strict;
use warnings;

sub get_root_networks {
    my ($self) = @_;

    my $rs = $self->search({ 'me.parent_id' => undef });
    return wantarray() ? $rs->all : $rs;
}

sub rebuild_tree {
    my $self = shift;

    my @nodes = $self->all();

    foreach my $node (@nodes) {
        my $supernet = $node->first_supernet();
        $supernet //= 0;
        $node->parent($supernet);
    }

}


1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:

