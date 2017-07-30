package App::Manoc::DB::ResultSet::VirtualMachine;
#ABSTRACT: ResultSet class for VirtualMachine

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::ResultSet';

=method unused

Resultset containing VirtualMachines which are not decommissioned and
are not in use by any Server

=cut

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

=method manoc_search( $query, $result)

Support for Manoc search feature

=cut

sub manoc_search {
    my ( $self, $query, $result ) = @_;

    my $type = $query->query_type;

    $type eq 'inventory' or $type eq 'server' or return;

    my $pattern = $query->sql_pattern;
    my $it =
        $self->search( [ { uuid => { -like => $pattern } }, { name => { -like => $pattern } } ],
        { order_by => 'name' } );

    while ( my $v = $it->next ) {
        my $item = App::Manoc::DB::Search::Result::Row->new( row => $v );
        $result->add_item($item);
    }
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
