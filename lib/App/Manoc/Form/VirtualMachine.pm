# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package App::Manoc::Form::VirtualMachine;
use HTML::FormHandler::Moose;
use namespace::autoclean;

use App::Manoc::Form::Helper qw/bs_block_field_helper/;

extends 'App::Manoc::Form::Base';
with 'App::Manoc::Form::TraitFor::SaveButton';
with 'App::Manoc::Form::TraitFor::Horizontal';

has '+name'        => ( default => 'form-virtualmachine' );
has '+html_prefix' => ( default => 1 );

has '+item_class' => ( default => 'VirtualMachine' );

sub build_render_list {
    return [
        qw/
            name identifier
            resources_block
            hyper_block

            save
            csrf_token
            /
    ];
}

has_block 'resources_block' => (
    render_list => [ 'ram_memory', 'vcpus' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_block 'hyper_block' => (
    render_list => [ 'virtinfr', 'hypervisor' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_field 'name' => (
    type     => 'Text',
    size     => 15,
    required => 1,
    label    => 'Name',
);

has_field 'identifier' => (
    type  => 'Text',
    size  => 36,
    label => 'Identifier',
);

has_field 'vcpus' => (
    type     => 'Integer',
    required => 1,
    label    => 'Virtual CPUs',

    bs_block_field_helper( { label => 2, input => 4 } )
);

has_field 'ram_memory' => (
    type     => 'Integer',
    required => 1,
    label    => 'RAM (Mb)',

    bs_block_field_helper( { label => 2, input => 4 } )
);

has_field 'virtinfr' => (
    type     => 'Select',
    label    => 'Virtual Infrastructure',
    nullable => 1,

    empty_select => '--- Choose ---',
    bs_block_field_helper( { label => 2, input => 4 } ),
    element_class => 'selectpicker',
    element_attr  => { 'data-live-search' => 'true' }
);

has_field 'hypervisor' => (
    type         => 'Select',
    label        => 'Hypervisor',
    nullable     => 1,
    empty_select => '--- Choose ---',
    bs_block_field_helper( { label => 2, input => 4 } ),
    element_class => 'selectpicker',
    element_attr  => { 'data-live-search' => 'true' }
);

has_field 'notes' => (
    type  => 'TextArea',
    label => 'Notes',
);

sub options_hypervisor {
    my $self = shift;

    return unless $self->schema;

    my @options;
    my @rs = $self->schema->resultset('Server')->hypervisors()->all;

    foreach my $b (@rs) {
        my $option = {
            label => $b->label,
            value => $b->id
        };
        push @options, $option;
    }

    return @options;
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
