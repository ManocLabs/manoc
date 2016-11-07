# Copyright 2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::Form::Server;
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::SaveButton';
with 'Manoc::Form::TraitFor::RackOptions';

has '+item_class' => ( default => 'Server' );

has '+name'        => ( default => 'form-asset' );
has '+html_prefix' => ( default => 1 );

has_field 'vendor' => (
    label    => 'Vendor',
    type     => 'Text',
    size     => 16,
    required => 1,
    apply    => [
        'Str',
        {
            check   => sub { $_[0] =~ /\w/ },
            message => 'Invalid vendor'
        },
    ]
);

has_field 'model' => (
    label    => 'Model',
    type     => 'Text',
    required => 1,
    size     => 16,
    apply    => [
        'Str',
        {
            check   => sub { $_[0] =~ /\w/ },
            message => 'Invalid model'
        },
    ]
);

has_field 'inventory' => (
    label    => 'Inventory',
    type     => 'Text',
    size     => 32,
    required => 0,
);

has_field 'serial' => (
    label    => 'Serial',
    type     => 'Text',
    size     => 32,
    required => 0,
);

has_field 'os' => (
    label    => 'OS',
    type     => 'Text',
    size     => 32,
    required => 0,
);

has_field 'os_ver' => (
    label    => 'OS Version',
    type     => 'Text',
    size     => 32,
    required => 0,
);


has_field 'dismissed' => (
    label        => 'Dismissed?',
    type         => 'Boolean',
    option_label => ' '
);

has_field 'rack' => (
    type         => 'Select',
    empty_select => '---Choose a Rack---',
);

has_field 'building' => (
    type         => 'Select',
    empty_select => '---Choose a Building---',
);

has_field 'room' => (
    label    => 'Room',
    type     => 'Text',
    size     => 16,
    required => 1,
);

has_field 'floor' => (
    label    => 'Floor',
    type     => 'Text',
    size     => 4,
    required => 1,
);

has_field 'n_procs' => (
    label    => 'Number of processors',
    type     => 'Integer',
    required => 1,
);

has_field 'n_cores_procs' => (
    label    => 'Cores per processor',
    type     => 'Integer',
    required => 1,
);

has_field 'proc_freq' => (
    label    => 'Processor frequency',
    type     => 'Text',
    required => 1,
);

has_field 'ram_memory' => (
    label    => 'RAM (Mb)',
    type     => 'Integer',
    required => 1,
);

has_field 'storage1_size' => (
    label    => 'Primary storage (GB)',
    type     => 'Text',
    required => 1,
);

has_field 'storage2_size' => (
    label    => 'Secondary storage (GB)',
    type     => 'Text',
    required => 1,
);

has_field 'notes' => (
    label => 'Notes',
    type  => 'TextArea',
);

sub options_building {
    my $self = shift;
    return unless $self->schema;
    my @buildings = $self->schema->resultset('Building')->all;
    my @options = map { { value => $_->id, label => $_->name } } @buildings;
    return @options;
}

sub options_rack {
    my $self = shift;

    return unless $self->schema;

    return $self->get_rack_options;
}

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
1;
