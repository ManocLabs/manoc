package App::Manoc::Form::CSVImport::Server;

use HTML::FormHandler::Moose;
use namespace::autoclean;

extends 'App::Manoc::Form::CSVImport';

has_field 'create_hw' => ();

has '+required_columns' => (
    default => sub {
        [qw/hostname/];
    }
);

has '+optional_columns' => (
    default => sub {
        [
            qw/
                os os_ver
                ethernet_static_ipaddr
                wireless_static_ipaddr
                notes
                /
        ];
    }

);

has '+column_names' => (
    default => sub {
        {
            'ethernet IP' => 'ethernet_static_ipaddr',
            'wireless IP' => 'wireless_static_ipaddr',
            'os ver'      => 'os_ver',
        };
    }
);

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
