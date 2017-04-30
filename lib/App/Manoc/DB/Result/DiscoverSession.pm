# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::DB::Result::DiscoverSession;

use parent 'App::Manoc::DB::Result';

use strict;
use warnings;

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
    snmp_community => {
        data_type     => 'varchar',
        size          => 64,
        default_value => 'NULL',
        is_nullable   => 1,
    },
    use_netbios => {
        data_type     => 'int',
        size          => '1',
        default_value => '0',
    },
);

__PACKAGE__->set_primary_key(qw(id));

__PACKAGE__->has_many(
    discovered_hosts => 'App::Manoc::DB::Result::DiscoveredHost',
    'session_id', { cascade_delete => 1 }
);

sub is_new { return shift->status eq STATUS_NEW }

sub is_done { return shift->status eq STATUS_DONE }

sub is_running { return shift->status eq STATUS_RUNNING }

sub is_stopped { return shift->status eq STATUS_STOPPED }

sub is_waiting { return shift->status eq STATUS_WAITING }

sub restart {
    my $self = shift;

    $self->status(STATUS_NEW);
    $self->next_addr( $self->from_addr );
}

sub display_status {
    my $self   = shift;
    my $status = $self->status;

    $status eq STATUS_NEW     and return 'new';
    $status eq STATUS_RUNNING and return 'running';
    $status eq STATUS_STOPPED and return 'stopped';
    $status eq STATUS_WAITING and return 'waiting';
    $status eq STATUS_DONE    and return 'done';
}

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
