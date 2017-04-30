package App::Manoc::Controller::Group;
#ABSTRACT: Group controller

use Moose;

##VERSION

use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; }
with 'App::Manoc::ControllerRole::CommonCRUD';

use App::Manoc::Form::Group;

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'group',
        }
    },
    class                   => 'ManocDB::Group',
    form_class              => 'App::Manoc::Form::Group',
    enable_permission_check => 1,
);

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
