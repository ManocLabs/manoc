# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::IPNetwork;

use HTML::FormHandler::Moose;
extends 'Manoc::Form::Base';

use namespace::autoclean;


has '+name' => ( default => 'form-ipnetwork' );
has '+html_prefix' => ( default => 1 );

has '+item_class' => (
    default => 'IPNetwork'
);

has_field 'address' => (
    type => 'Text',
    size => 15,
    required => 1,
    label => 'address',
);

has_field 'prefix' => (
    type => 'Integer',
    required => 1,
    label => 'prefix',
);

has_field 'name' => (
    type => 'TextArea',
    required => 1,
    label => 'name',
);

has_field 'vlan_id' => (
    type => 'Select',
    label => 'vlan',
    empty_select => '---Choose a VLAN---',
);

has_field 'description' => (
    type => 'TextArea',
    label => 'description',
);

sub options_vlan_id {
    my $self = shift;

    return unless $self->schema;
    my $rs = $self->schema->resultset('Vlan')->search( {}, { order_by => 'id' } );
    return map +{ value => $_->id, label => $_->name . " (" . $_->id . ")" }, $rs->all();
}

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
