package App::Manoc::Controller::DHCPServer;
#ABSTRACT: DHCPServer Controller

use Moose;

##VERSION

use namespace::autoclean;
BEGIN { extends 'App::Manoc::ControllerBase::CRUD' }

use App::Manoc::Form::DHCPServer;
use App::Manoc::Form::DHCPSharedNetwork;

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'dhcpserver',
        }
    },
    class      => 'ManocDB::DHCPServer',
    form_class => 'App::Manoc::Form::DHCPServer',
);

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
