package App::Manoc::Form::BaseDBIC;

use Moose;
use namespace::autoclean;

extends 'App::Manoc::Form::Base';
with 'HTML::FormHandler::TraitFor::Model::DBIC';

__PACKAGE__->meta->make_immutable;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
