package App::Manoc::Form::CSVImport::WorkstationHW;

use HTML::FormHandler::Moose;
use namespace::autoclean;

extends 'App::Manoc::Form::CSVImport';

has '+required_columns' => (
    default => sub {
        [qw/model vendor ram_memory cpu_model/];
    }
);

has '+optional_columns' => (
    default => sub {
        [
            qw/
                proc_freq  inventory serial
                storage1_size storage2_size notes
                ethernet_addr wireless_addr
                /
        ];
    }

);

has '+column_names' => (
    default => sub {
        return {
            'cpu'       => 'cpu_model',
            'frequency' => 'proc_freq',
            'ram'       => 'ram_memory',
            'storage 1' => 'storage1_size',
            'storage 2' => 'storage2_size',
            'wireless'  => 'wireless_addr',
            'ethernet'  => 'ethernet_addr',
        };
    }
);

has '+lookup_columns' => ( default => sub { [ "serial", [qw /vendor inventory/] ] } );

sub find_entry {
    my ( $self, $data ) = @_;

    my $rs = $self->resultset;
    if ( exists $data->{serial} ) {
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
