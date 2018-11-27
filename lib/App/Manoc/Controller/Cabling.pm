package App::Manoc::Controller::Cabling;
#ABSTRACT: Cabling Controller

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
    form_class          => 'App::Manoc::Form::Cabling',
    view_object_perm    => undef,
    object_list_options => { prefetch => [ 'interface2', 'serverhw_nic' ] },
);

sub test_form {
    my ( $self, $c ) = @_;

    my $form = App::Manoc::Form::Cabling->new(
        {
            ctx => $c,
        }
    );
    $c->stash( form => $form );

    if ( $c->stash->{is_xhr} && $c->req->method eq 'POST' ) {
        my $process_status = $form->process(
            params => $c->req->params,
            item   => $c->model('ManocDB::CablingMatrix')->new_result( {} )
        );
        $c->debug and $c->log->debug("Form process status = $process_status");

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
