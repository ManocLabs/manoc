
# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Controller::About;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use English '-no_match_vars';

=head1 NAME

Manoc::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('/about/stats');
}

=head2 statistics

=cut

sub stats : Private {
    my ( $self, $c ) = @_;

    my $schema = $c->model('ManocDB');

    eval { require SNMP::Info };
    my $snmpinfo_ver = ($@ ? 'n/a' : $SNMP::Info::VERSION);

    my $stats =  {
	manoc_ver    => $Manoc::VERSION,
	db_version   => $Manoc::DB::VERSION,
	dbi_ver      => $DBI::VERSION,
	dbic_ver     => $DBIx::Class::VERSION,
	catalyst_ver => $Catalyst::VERSION,
	snmpinfo_ver => $snmpinfo_ver,
	perl_version => $PERL_VERSION,

	tot_racks    => $schema->resultset('Rack')->count,
	tot_devices  => $schema->resultset('Device')->count,
        tot_ifaces   => $schema->resultset('IfStatus')->count,
	tot_cdps     => $schema->resultset('CDPNeigh')->count,
	mat_entries  => $schema->resultset('Mat')->count,
        arp_entries  => $schema->resultset('Arp')->count
    };

    $c->stash(stats => $stats);
}

=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
