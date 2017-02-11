# Copyright 2011-2016 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::ServerHW;
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::Horizontal';
with 'Manoc::Form::TraitFor::SaveButton';
with 'Manoc::Form::TraitFor::RackOptions';

with 'Manoc::Form::HWAsset::Location';

use Manoc::DB::Result::HWAsset;

use namespace::autoclean;

has '+item_class'  => ( default => 'ServerHW' );
has '+name'        => ( default => 'form-serverhw' );
has '+html_prefix' => ( default => 1 );

has hide_location => (
    isa     => 'Bool',
    is      => 'rw',
    default => 0,
);

has_block 'processor_block' => (
    render_list => [ 'cpu_model', 'proc_freq', 'n_procs', 'n_cores_proc' ],
    tag         => 'div',
    class       => ['form-group'],
);

sub build_render_list {
    my $self = shift;

    return [
        'inventory',
        'vendor', 'model', 'serial',
        'location',
        'warehouse',
        'location_block',
        'rack_block',

        'processor_block',
        'ram_memory',
        'storage1_size', 'storage2_size',

        'save',
        'csrf_token',
    ];
}

has_field 'inventory' => (
    type  => 'Text',
    size  => 32,
    label => 'Inventory',
);

has_field 'vendor' => (
    type     => 'Text',
    size     => 32,
    required => 1,
    label    => 'Vendor',
);

has_field 'model' => (
    type     => 'Text',
    size     => 32,
    required => 1,
    label    => 'Model',
);

has_field 'serial' => (
    type  => 'Text',
    size  => 32,
    label => 'Serial',
);

has_field 'cpu_model' => (
    type     => 'Text',
    size     => 32,
    label    => 'CPU Model',
    required => 1,

    do_wrapper => 0,
    # we set wrapper=>0 so we don't have the inner div too!
    tags => {
        before_element => '<div class="col-sm-2">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-2'],

);

has_field 'proc_freq' => (
    type  => 'Float',
    label => 'Freq.',

    element_attr => { placeholder => 'MHz' },

    do_wrapper => 0,
    # we set wrapper=>0 so we don't have the inner div too!
    tags => {
        before_element => '<div class="col-sm-2">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-1'],
);

has_field 'n_procs' => (
    type  => 'Integer',
    label => 'Number',

    do_wrapper => 0,
    # we set wrapper=>0 so we don't have the inner div too!
    tags => {
        before_element => '<div class="col-sm-1">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-1'],
);

has_field 'n_cores_proc' => (
    type  => 'Integer',
    label => 'Core per proc.',

    do_wrapper => 0,
    # we set wrapper=>0 so we don't have the inner div too!
    tags => {
        before_element => '<div class="col-sm-1">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-2'],
);

has_field 'ram_memory' => (
    type         => 'Integer',
    label        => 'RAM Memory',
    required     => 1,
    element_attr => { placeholder => 'MB' },

);

has_field 'storage1_size' => (
    type         => 'Integer',
    label        => 'Primary storage',
    element_attr => { placeholder => 'GB' },
);

has_field 'storage2_size' => (
    type         => 'Integer',
    label        => 'Secondary storage (GB)',
    element_attr => { placeholder => 'GB' },
);

has_field 'notes' => (
    type  => 'Text',
    label => 'Notes',
);

override validate_model => sub {
    my $self = shift;
    my $item = $self->item;

    my $found_error = super() || 0;

    return $found_error unless $item->in_storage;

    my $field = $self->field('inventory');
    return $found_error if $field->has_errors;

    my $value = $field->value;
    return $found_error unless defined $value;

    my $rs = $self->schema->resultset('HWAsset');
    my $unique_filter = { inventory => $value };
    $item->id and $unique_filter->{id} = { '!=' => $item->id };
    my $count = $rs->search($unique_filter)->count;

    if ( $count > 0 ) {
        my $field_error =
            $field->get_message('unique') ||
            $field->unique_message ||
            'Duplicate value for [_1]';
        $field->add_error( $field_error, $field->loc_label );
        $found_error++;
    }

    return $found_error;
};

override 'update_model' => sub {
    my $self   = shift;
    my $values = $self->value;
    my $item   = $self->item;

    $self->hide_location and
        $values->{location} = Manoc::DB::Result::HWAsset->LOCATION_WAREHOUSE;
    $self->_set_value($values);
    $self->update_model_location();

    super();
};

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
