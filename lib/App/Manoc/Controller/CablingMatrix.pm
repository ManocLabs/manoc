package App::Manoc::Controller::CablingMatrix;
#ABSTRACT: CablingMatrix Controller

use Moose;

##VERSION

#TODO: if this controller should be used, it's jus for matrix view

use namespace::autoclean;

BEGIN { extends 'App::Manoc::ControllerBase::CRUD'; }

__PACKAGE__->config(
    # define PathPart
    action => {
        setup => {
            PathPart => 'cabling',
        }
    },
    class               => 'ManocDB::CablingMatrix',
    form_class          => 'App::Manoc::Form::DeviceCabling',
    view_object_perm    => undef,
    object_list_options => { prefetch => [ 'interface2', 'serverhw_nic' ] },
);

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
