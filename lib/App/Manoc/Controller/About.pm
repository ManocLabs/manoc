package App::Manoc::Controller::About;
#ABSTRACT: Controller for about page

use Moose;

##VERSION

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use English '-no_match_vars';

=action index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('/about/stats');
}

=action stats

=cut

sub stats : Private {
    my ( $self, $c ) = @_;

    my $schema = $c->model('ManocDB');

    eval { require SNMP::Info };
    my $snmpinfo_ver = ( $@ ? 'n/a' : $SNMP::Info::VERSION );

    my $stats = {
        manoc_ver    => $App::Manoc::VERSION,
        db_version   => $App::Manoc::DB::SCHEMA_VERSION,
        dbi_ver      => $DBI::VERSION,
        dbic_ver     => $DBIx::Class::VERSION,
        catalyst_ver => $Catalyst::VERSION,
        snmpinfo_ver => $snmpinfo_ver,
        perl_version => $PERL_VERSION,

        tot_racks   => $schema->resultset('Rack')->count,
        tot_devices => $schema->resultset('Device')->count,
        tot_ifaces  => $schema->resultset('DeviceIfStatus')->count,
        tot_cdps    => $schema->resultset('CDPNeigh')->count,
        mat_entries => $schema->resultset('Mat')->count,
        arp_entries => $schema->resultset('Arp')->count
    };

    $c->stash( stats => $stats );
}

__PACKAGE__->meta->make_immutable;

1;
