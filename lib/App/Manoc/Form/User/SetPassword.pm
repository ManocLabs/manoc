package App::Manoc::Form::User::SetPassword;

use HTML::FormHandler::Moose;

##VERSION

extends 'App::Manoc::Form::Base';
with 'App::Manoc::Form::TraitFor::SaveButton';

has '+name'        => ( default => 'form-user' );
has '+html_prefix' => ( default => 1 );

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

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
