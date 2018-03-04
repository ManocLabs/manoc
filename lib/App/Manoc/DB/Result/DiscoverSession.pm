package App::Manoc::DB::Result::DiscoverSession;
#ABSTRACT: A model object for discovery sessions

use strict;
use warnings;

##VERSION

use parent 'App::Manoc::DB::Result';

use constant {
    STATUS_NEW     => 'N',
    STATUS_RUNNING => 'R',
    STATUS_STOPPED => 'S',
    STATUS_WAITING => 'W',
    STATUS_DONE    => 'D',
};

__PACKAGE__->load_components(qw/+App::Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('discover_sessions');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0
    },
    'status' => {
        data_type     => 'varchar',
        is_nullable   => 0,
        size          => 1,
        default_value => STATUS_NEW,
    },
    'from_addr' => {
        data_type    => 'varchar',
        size         => '15',
        is_nullable  => 0,
        ipv4_address => 1,
    },
    'to_addr' => {
        data_type    => 'varchar',
        size         => '15',
        is_nullable  => 0,
        ipv4_address => 1,
    },
    'next_addr' => {
        data_type    => 'varchar',
        size         => '15',
        is_nullable  => 1,
        ipv4_address => 1,
    },
    use_snmp => {
        data_type     => 'int',
        size          => '1',
        default_value => '0',
    },
    use_netbios => {
        data_type     => 'int',
        size          => '1',
        default_value => '0',
    },
    credentials_id => {
        data_type      => 'int',
        is_foreign_key => 1,
        is_nullable    => 0,
    },
);

__PACKAGE__->set_primary_key(qw(id));

__PACKAGE__->has_many(
    discovered_hosts => 'App::Manoc::DB::Result::DiscoveredHost',
    'session_id', { cascade_delete => 1 }
);

__PACKAGE__->belongs_to(
    credentials => 'App::Manoc::DB::Result::Credentials',
    { 'foreign.id' => 'self.credentials_id' }
);

=method is_new

=cut

sub is_new { return shift->status eq STATUS_NEW }

=method is_done

=cut

sub is_done { return shift->status eq STATUS_DONE }

=method is_running

=cut

sub is_running { return shift->status eq STATUS_RUNNING }

=method is_stopped

=cut

sub is_stopped { return shift->status eq STATUS_STOPPED }

=method is_waiting

=cut

sub is_waiting { return shift->status eq STATUS_WAITING }

=method restart

Set status to new and reset next_address

=cut

sub restart {
    my $self = shift;

    $self->status(STATUS_NEW);
    $self->next_addr( $self->from_addr );
}

=method display_status

Show current status in human readable form

=cut

sub display_status {
    my $self   = shift;
    my $status = $self->status;

    $status eq STATUS_NEW     and return 'new';
    $status eq STATUS_RUNNING and return 'running';
    $status eq STATUS_STOPPED and return 'stopped';
    $status eq STATUS_WAITING and return 'waiting';
    $status eq STATUS_DONE    and return 'done';
}

=method progression

Return the percentage of scanned addresses as a integer

=cut

sub progression {
    my $self = shift;

    $self->status eq STATUS_NEW  and return 0;
    $self->status eq STATUS_DONE and return 100;

    my $current = defined( $self->next_addr ) ? $self->next_addr->numeric - 1 :
        $self->from_addr->numeric;
    my $done = $current - $self->from_addr->numeric;

    my $total = $self->to_addr->numeric - $self->from_addr->numeric;

    return int( $done / $total * 100 );
}

=for Pod::Coverage sqlt_deploy_hook

=cut

sub sqlt_deploy_hook {
    my ( $self, $sqlt_table ) = @_;

    $sqlt_table->add_index(
        name   => 'idx_ipblock_from_to',
        fields => [ 'from_addr', 'to_addr' ]
    );
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
