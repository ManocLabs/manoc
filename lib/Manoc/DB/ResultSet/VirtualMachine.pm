# Copyright 2011-2016 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::ResultSet::VirtualMachine;

use base 'DBIx::Class::ResultSet';
use strict;
use warnings;

sub unused {
    my ( $self ) = @_;

    my $used_vm_ids = $self->result_source->schema->resultset('Server')
        ->search(
            {
              #  'subquery.dismissed' => 0,
                'subquery.vm_id'  => { -is_not => undef }
            },
            {
                alias => 'subquery',
            })
        ->get_column('vm_id');

    my $assets = $self->search(
        {
            'vm.id' =>  {
                -not_in => $used_vm_ids->as_query,
            }
        },
        {
            alias => 'vm'
        }
    );

    return $assets;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
