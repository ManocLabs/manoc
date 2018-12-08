package App::Manoc::ControllerRole::ObjectForm;
#ABSTRACT: Role for editing objects with a form

use Moose::Role;
use Try::Tiny;

##VERSION

use namespace::autoclean;

use MooseX::MethodAttributes::Role;

with 'App::Manoc::ControllerRole::Object';

has 'form_class' => (
    is  => 'rw',
    isa => 'ClassName'
);

# can override form_class during object creation
has 'create_form_class' => (
    is  => 'rw',
    isa => 'ClassName'
);

# can override form_class during object editing
has 'edit_form_class' => (
    is  => 'rw',
    isa => 'ClassName'
);

has 'form_success_url' => (
    is  => 'rw',
    isa => 'Str'
);

has 'object_updated_message' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Updated',
);

has 'create_object_perm' => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    default => 'create',
);

has 'edit_object_perm' => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    default => 'edit',
);

=action object_form_create

=cut

sub object_form_create : Private {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{resultset}->new_result( {} );

    $self->create_form_class and
        $c->stash( form_class => $self->create_form_class );

    $c->stash( object => $object, );

    $c->forward('object_form');
}

=action object_form_edit

=cut

sub object_form_edit : Private {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};
    $self->edit_object_perm and
        $c->require_permission( $object, $self->edit_object_perm );

    $self->edit_form_class and
        $c->stash( form_class => $self->edit_form_class );

    $c->forward('object_form');
}

=action object_form

Private action which handle creation and editing of resources. Form
defaults can be injected using form_defaults in stash. Form is created
by get_form method unless already set in stash->{form}.

=cut

sub object_form : Private {
    my ( $self, $c ) = @_;

    my $item = $c->stash->{object};
    my $form = $c->stash->{form};

    if ( !$form ) {
        $form = $self->get_form($c);
        $c->stash( form => $form );
    }

    my $is_api = $c->stash->{is_api};
    my $is_xhr = $c->stash->{is_xhr};

    $c->stash(
        form   => $form,
        action => $c->uri_for( $c->action, $c->req->captures ),
    );

    my %process_params;
    $process_params{item} = $c->stash->{object};

    # prepare input, using body_parameters for forms or
    # api_request_data for api calls
    my $data = $is_api ? $c->stash->{api_request_data} : $c->req->body_parameters;
    $process_params{params} = $data;

    # allow partial updates
    if ( $item && $c->req->method eq 'POST' && ( $is_api || $is_xhr ) ) {
        my @inactive_fields;

        foreach my $field ( $form->all_fields ) {
            my $name = $field->name;
            next if exists $data->{$name};

            next if $field->type eq 'Button';
            next if $field->type eq 'ButtonTag';
            next if $field->type eq 'Submit';

            $c->debug and
                $c->log->debug( "Removing $name" . $field->type . " from active fields" );
            push @inactive_fields, $name;
        }

        @inactive_fields and
            $process_params{inactive} = \@inactive_fields;
    }

    if ( $c->stash->{form_defaults} ) {
        $process_params{defaults}              = $c->stash->{form_defaults};
        $process_params{use_defaults_over_obj} = 1;
    }
    if ( $self->can("get_form_process_params") ) {
        %process_params = $self->get_form_process_params( $c, %process_params );
    }

    if ( $c->stash->{form_require_post} ) {
        $process_params{posted} = $c->req->method eq 'POST';
    }

    # the "process" call has all the saving logic,
    #   if it returns False, then a validation error happened
    my $process_status = $form->process(%process_params);
    $c->debug and $c->log->debug("Form process status = $process_status");

    return unless $process_status;

    $c->stash->{object_id} = $form->item_id;
    $c->stash->{message}   = $self->object_updated_message;
}

=action object_form_ajax_response

=cut

sub object_form_ajax_response : Private {
    my ( $self, $c ) = @_;

    my $form           = $c->stash->{form};
    my $process_status = $form->is_valid;

    my $json_data = {};

    $json_data->{form_ok} = $process_status ? 1         : 0;
    $json_data->{status}  = $process_status ? 'success' : 'error';

    if ($process_status) {
        $c->stash->{object_id} = $form->item_id;

        $json_data->{message}   = $self->object_updated_message;
        $json_data->{redirect}  = $self->get_form_success_url($c)->as_string;
        $json_data->{object_id} = $form->item_id;

        $form->item->can('label') and
            $json_data->{object_label} = $form->item->label;
    }
    elsif ( $c->stash->{object_form_ajax_add_html} ) {
        my $template_name = $c->stash->{ajax_form_template};
        $template_name ||= $c->namespace . "/form.tt";

        # render as a fragment{
        $c->stash->{no_wrapper} = 1;
        my $html = $c->forward( "View::TT", "render", [ $template_name, $c->stash ] );

        $json_data->{html} = $html;
    }

    $c->stash->{json_data}    = $json_data;
    $c->stash->{current_view} = 'JSON';

}

=method get_form

Create a new form using form_class configuration parameter.

=cut

sub get_form {
    my ( $self, $c ) = @_;

    my $class = $c->stash->{form_class} || $self->form_class;
    $class or die "Form class not set (use form_class)";

    my $parameters = $c->stash->{form_parameters} || {};
    return $class->new( ctx => $c, %$parameters );
}

=method get_form_success_url

Get the URL to redirect after successful editing.  Use
form_success_url or try to use the view action in the current
namespace.

=cut

sub get_form_success_url {
    my ( $self, $c ) = @_;

    my $form_success_url = $c->stash->{form_success_url} ||
        $self->form_success_url ||
        $c->uri_for_action( $c->namespace . "/view", [ $c->stash->{object_id} ] );

    return $form_success_url;
}

=action object_form_delete

Private action which handle deleting of resources.

=cut

sub object_form_delete : Private {
    my ( $self, $c ) = @_;

    my $object = $c->stash->{object};
    $self->delete_object_perm and
        $c->require_permission( $object, $self->delete_object_perm );

    if ( $c->req->method eq 'POST' ) {
        my $success = $self->delete_object($c) || 0;
        $c->stash(
            {
                form_delete_posted  => 1,
                form_delete_success => $success
            }
        );
    }
    else {
        $c->stash( form_delete_posted => 0 );
    }

}

=action object_form_delete_ajax_response

=cut

sub object_form_delete_ajax_response : Private {
    my ( $self, $c ) = @_;

    my $process_status = $c->stask->{form_delete_posted} && $c->stash->{form_delete_success};

    my $json_data = {};

    $json_data->{form_ok} = $process_status ? 1         : 0;
    $json_data->{status}  = $process_status ? 'success' : 'error';

    if ($process_status) {
        $json_data->{message}  = $self->object_deleted_message;
        $json_data->{redirect} = $self->get_delete_success_url($c)->as_string;
    }
    else {
        $json_data->{object_id} = $c->stash->{object_id};

        if ( $c->stash->{object_form_ajax_add_html} ) {
            my $template_name = $c->stash->{ajax_delete_form_template};
            $template_name ||= "generic_delete.tt";

            # render as a fragment{
            $c->stash->{no_wrapper} = 1;
            my $html = $c->forward( "View::TT", "render", [ $template_name, $c->stash ] );

            $json_data->{html} = $html;
        }
    }
    $c->stash->{json_data}    = $json_data;
    $c->stash->{current_view} = 'JSON';
}

=method delete_object

Delete the object using its C<delete> method.

=cut

sub delete_object {
    my ( $self, $c ) = @_;

    my $success = 0;
    try {
        $c->stash->{object}->delete;
        $success = 1;
    };
    return $success;
}

=method get_delete_failure_url

Default is the view action in current namespace.

=cut

sub get_delete_failure_url {
    my ( $self, $c ) = @_;

    my $action = $c->namespace . "/view";
    return $c->uri_for_action( $action, [ $c->stash->{object_pk} ] );
}

=method get_delete_success_url

Default is the list action in current namespace.

=cut

sub get_delete_success_url {
    my ( $self, $c ) = @_;

    return $c->uri_for_action( $c->namespace . "/list" );
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
