package Manoc::Form::CSVImport::Server;

use HTML::FormHandler::Moose;
use namespace::autoclean;

extends 'Manoc::Form::CSVImport';

has_field 'create_vm' => ();

has_field 'create_hw' => ();

has '+required_columns' => (
    default => sub {
        [qw/hostname address/];
    }
);

has '+optional_columns' => (
    default => sub {
        [
            qw/
                os os_ver
                /
        ];
    }

);

has '+column_names' => (
    default => sub {
        {
            'cpu'        => 'cpu_model',
            'ram'        => 'ram_memory',
            'processors' => 'n_procs',
            'cores'      => 'n_cores_proc',
            'frequency'  => 'proc_freq',
            'storage 1'  => 'storage1_size',
            'storage 2'  => 'storage2_size',
        };
    }
);

has '+lookup_columns' => ( default => sub { [ "serial", [qw /vendor inventory/] ] } );

sub find_entry {
    my ( $self, $data ) = @_;

    my $rs = $self->resultset;
    if ( exists $data->{serial} ) {
        print STDERR "search by serial\n";
        my $entry = $rs->search(
            {
                'hwasset.serial' => $data->{serial},
            },
            {
                join => 'hwasset'
            }
        )->first;
        $entry and return $entry;
    }

    if ( exists $data->{inventory} ) {
        print STDERR "search by inventory\n";
        my $entry = $rs->search(
            {
                'hwasset.inventory' => $data->{inventory},
            },
            {
                join => 'hwasset'
            }
        )->first;
        $entry and return $entry;
    }

}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
