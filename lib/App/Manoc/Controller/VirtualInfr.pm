package App::Manoc::Controller::VirtualInfr;
#ABSTRACT: VirtualInfr controller
use Moose;

##VERSION

use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }
with 'App::Manoc::ControllerRole::CommonCRUD';

use App::Manoc::Form::VirtualInfr;

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'vinfr',
        }
    },
    class      => 'ManocDB::VirtualInfr',
    form_class => 'App::Manoc::Form::VirtualInfr',
);

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
