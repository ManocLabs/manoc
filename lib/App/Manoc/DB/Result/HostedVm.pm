package App::Manoc::DB::Result::HostedVm;
#ABSTRACT: A model object to represent VirtualMachine associations  to Hypervisor

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

__PACKAGE__->load_components(
    qw/
        +App::Manoc::DB::Helper::Row::TupleArchive
        /
);

__PACKAGE__->table('hosted_vm');

__PACKAGE__->add_columns(
    vm_id => {
        data_type      => 'int',
        is_nullable    => 0,
        is_foreign_key => 1,
    },

    hypervisor_id => {
        data_type      => 'int',
        is_nullable    => 0,
        is_foreign_key => 1,
    },

);

__PACKAGE__->set_tuple_archive_columns(qw(vm_id hypervisor_id));

__PACKAGE__->set_primary_key(qw(vm_id hypervisor_id firstseen));

__PACKAGE__->belongs_to(
    vm => 'App::Manoc::DB::Result::VirtualMachine',
    'vm_id',
);

__PACKAGE__->belongs_to(
    hypervisor => 'App::Manoc::DB::Result::Server',
    'hypervisor_id',
);

=for Pod::Coverage sqlt_deploy_hook

=cut

sub sqlt_deploy_hook {
    my ( $self, $sqlt_schema ) = @_;

    $sqlt_schema->add_index( name => 'idx_hostedvm_vm',     fields => ['vm_id'] );
    $sqlt_schema->add_index( name => 'idx_hostedvm_hyperv', fields => ['hypervisor_id'] );

}

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
