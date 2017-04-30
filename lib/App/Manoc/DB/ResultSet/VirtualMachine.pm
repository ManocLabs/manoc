package App::Manoc::DB::ResultSet::VirtualMachine;

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

sub unused {
    my ($self) = @_;

    my $used_vm_ids = $self->result_source->schema->resultset('Server')->search(
        {
            'subquery.decommissioned' => 0,
            'subquery.vm_id'          => { -is_not => undef }
        },
        {
            alias => 'subquery',
        }
    )->get_column('vm_id');

    my $me = $self->current_source_alias;
    my $rs = $self->search(
        {
            "$me.id" => {
                -not_in => $used_vm_ids->as_query,
            }
        },
    );

    return wantarray ? $rs->all : $rs;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
