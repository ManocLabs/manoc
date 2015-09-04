# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

# A frontend for CISCO IOS devices still using telnet

package Manoc::Manifold::Telnet::IOS;

use Moose;

with 'Manoc::ManifoldRole::Base';
with 'Manoc::ManifoldRole::SSH';

use Try::Tiny;


sub _build_arp_table {
    my $self = shift;
    my $session = $self->session;

    my %arp_table;

    try {
	my @data = $self->cmd('/sbin/arp');
	chomp @data;

	# 192.168.1.1 ether 00:b6:aa:f5:bb:6e C eth1
	foreach my $line (@data) {
	    if ($line =~ /([0-9\.]+)\s+ether\s+([a-f0-9:]+)/ ) {
		my ($ip, $mac) = ($1, $2);
		$arp_table{$ip} =  $mac;
	    }
	}
	return \%arp_table;
    };

    $self->log->error('Error fetching arp table');
    return undef;
}





no Moose;
__PACKAGE__->meta->make_immutable;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
