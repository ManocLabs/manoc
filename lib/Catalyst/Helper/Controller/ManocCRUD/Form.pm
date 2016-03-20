package Catalyst::Helper::Controller::ManocCRUD::Form;

use namespace::autoclean;
use Moose;

extends 'HTML::FormHandler::Generator::DBIC';

sub _build_schema {
    my $self = shift;
    my $schema_name = $self->schema_name;
    eval "require $schema_name";
    die $@ if $@;
    return $schema_name->clone();
}

# Hack!!!
sub is_SQLite_auto_pk {
    return;
}

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:

