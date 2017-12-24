package App::Manoc::Form::User::ChangePassword;

use HTML::FormHandler::Moose;
##VERSION

extends 'App::Manoc::Form::BaseDBIC';
with 'App::Manoc::Form::TraitFor::SaveButton';

has '+name'        => ( default => 'form-user' );
has '+html_prefix' => ( default => 1 );

has_field 'old_password' => (
    type     => 'Password',
    label    => 'Old password',
    required => 1,
);

has_field 'password' => (
    type      => 'Password',
    label     => 'Password',
    required  => 1,
    minlength => 8,
);

has_field 'password2' => (
    type  => 'PasswordConf',
    label => 'Confirm Password',
);

has '+success_message' => ( default => 'Password updated.' );

sub validate_model {
    my $self = shift;
    my $item = $self->item;

    $item->check_password( $self->field('old_password')->value ) or
        $self->field('old_password')->add_error("Old password not valid");
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
