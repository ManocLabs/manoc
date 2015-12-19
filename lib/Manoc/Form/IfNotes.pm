# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::IfNotes;

use strict;
use warnings;
use HTML::FormHandler::Moose;

=head1 NAME

Manoc::Form::IfNotes

=head1 DESCRIPTION

Manoc Form for entering interface notes.

=cut

extends 'Manoc::Form::Base';

has '+name'        => ( default => 'form-ifnotes' );
has '+html_prefix' => ( default => 1 );

has 'device' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'interface' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has_field 'notes' => (
    type  => 'TextArea',
    label => 'Notes',
);

has_field 'save' => (
    type           => 'Submit',
    widget         => 'ButtonTag',
    element_attr   => { class => [ 'btn', 'btn-primary' ] },
    widget_wrapper => 'None',
    value          => "Save"
);

override 'update_model' => sub {
    my $self   = shift;
    my $values = $self->values;

    if ( $values->{notes} =~ /^\s*$/o && $self->item->in_storage ) {
        $self->item->delete();
        return 1;
    }

    $values->{device}    = $self->{device};
    $values->{interface} = $self->{interface};    #
    $self->_set_value($values);

    super();
};

=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:

