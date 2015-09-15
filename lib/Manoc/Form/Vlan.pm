# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Vlan;


use HTML::FormHandler::Moose;
use Manoc::Form::Types::VlanID;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::SaveButton';

has '+name' => ( default => 'form-vlan' );
has '+html_prefix' => ( default => 1 );

has_field 'vlan_range' => (
    type         => 'Select',
    label        => 'VLAN range',
    empty_select => '--- Choose ---',
    required     => 1,
);

has_field 'id' => (
    label => 'VLAN ID',
    type => 'Integer',
    apply => [ 'VlanID' ],
    required => 1,
);

has_field 'name' => (
    type     => 'Text',
    required => 1,
    label    => 'Vlan name',
    apply    => [
        'Str',
        {
            check => sub { $_[0] =~ /\w/ },
            message => 'Invalid Name'
        },
    ]
);

has_field 'description' => (
    label => 'Description',
    type  => 'TextArea'
);

override validate_model => sub {
    my $self = shift;

    my $vlan_id   = $self->field('id')->value;
    my $range_id  = $self->field('vlan_range')->value;
    my $range     = $self->schema->resultset('VlanRange')->find($range_id);
    my $vlan_from = $range->start;
    my $vlan_to   = $range->end;

    if ( $vlan_id < $vlan_from || $vlan_id > $vlan_to) {
        $self->field('id')->add_error("VLAN id must be within range $vlan_from-$vlan_to")
    }

    super();
};


sub options_range {
    my $self = shift;
    return unless $self->schema;

    my $rs = $self->schema->resultset('VlanRange')->search();
    return map +{ value => $_->id, label => $_->name }, $rs->all();
}

__PACKAGE__->meta->make_immutable;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:

