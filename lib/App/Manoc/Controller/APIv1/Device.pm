package App::Manoc::Controller::APIv1::Device;
#ABSTRACT: Controller for Device APIs

use Moose;
##VERSION

use namespace::autoclean;

BEGIN { extends 'App::Manoc::ControllerBase::APIv1CRUD' }

use App::Manoc::Form::Device::Edit;

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'device',
        }
    },
    class      => 'ManocDB::Device',
    form_class => 'App::Manoc::Form::Device::Edit',
);

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
