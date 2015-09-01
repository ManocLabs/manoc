# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Result::IPBlock;

use parent 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/+Manoc::DB::InflateColumn::IPv4/);

__PACKAGE__->table('ip_block');

__PACKAGE__->add_columns(
    id => {
	data_type         => 'int',
        is_auto_increment => 1,
        is_nullable       => 0
    },
    'name' => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 64
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
    'description' => {
        data_type   => 'varchar',
        is_nullable => 1,
        size        => 255
    },
);

__PACKAGE__->set_primary_key(qw(id));


sub arp_entries {
    my $self = shift;

    my $rs = $self->result_source->schema->resultset('Manoc::DB::Result::Arp');
    return $rs->search(
	{
	    'ipaddr' => {
		-between => [ $self->network->padded, $self->broadcast-padded ] }
	});
}

sub ip_entries {
    my $self = shift;

    my $rs = $self->result_source->schema->resultset('Manoc::DB::Result::Arp');
    return $rs->search(
	{
	    'ipaddr' => {
		-between => [ $self->network->padded, $self->broadcast->padded ] }
	});
}


1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
