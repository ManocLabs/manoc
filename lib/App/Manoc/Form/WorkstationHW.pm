# Copyright 2011-2016 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Form::WorkstationHW;
use HTML::FormHandler::Moose;

extends 'App::Manoc::Form::Base';
with
    'App::Manoc::Form::TraitFor::Horizontal',
    'App::Manoc::Form::TraitFor::SaveButton',
    'App::Manoc::Form::TraitFor::RackOptions',
    'App::Manoc::Form::HWAsset::Location';

use namespace::autoclean;

use App::Manoc::Form::Helper qw/bs_block_field_helper/;

use App::Manoc::DB::Result::HWAsset;
use App::Manoc::Form::Types ('MacAddress');

has '+item_class'  => ( default => 'WorkstationHW' );
has '+name'        => ( default => 'form-workstationhw' );
has '+html_prefix' => ( default => 1 );

has hide_location => (
    isa     => 'Bool',
    is      => 'rw',
    default => 0,
);

sub build_render_list {
    my $self = shift;

    return [
        'inventory',
        'vendor', 'model', 'serial',
        'location',
        'warehouse',
        'location_block',

        'processor_block1',
        'ram_memory',

        'storage_block',
        'macaddr_block',

        'notes',

        'save',
        'csrf_token',
    ];
}

has_block 'processor_block1' => (
    render_list => [ 'cpu_model', 'proc_freq' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_block 'storage_block' => (
    render_list => [ 'storage1_size', 'storage2_size', ],
    tag         => 'div',
    class       => ['form-group'],
);

has_block 'macaddr_block' => (
    render_list => [ 'ethernet_macaddr', 'wireless_macaddr', ],
    tag         => 'div',
    class       => ['form-group'],
);

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
    bs_block_field_helper( { label => 2, input => 4 } )
);

has_field 'proc_freq' => (
    type  => 'Float',
    label => 'Freq.',

    element_attr => { placeholder => 'MHz' },
    bs_block_field_helper( { label => 2, input => 4 } )
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

    bs_block_field_helper( { label => 2, input => 4 } )
);

has_field 'storage2_size' => (
    type         => 'Integer',
    label        => 'Secondary storage',
    element_attr => { placeholder => 'GB' },

    bs_block_field_helper( { label => 2, input => 4 } )
);

has_field 'ethernet_macaddr' => (
    type         => 'Text',
    apply        => [MacAddress],
    element_attr => {
        placeholder => 'Mac Address',
    },

    bs_block_field_helper( { label => 2, input => 4 } )
);

has_field 'wireless_macaddr' => (
    type         => 'Text',
    apply        => [MacAddress],
    element_attr => {
        placeholder => 'Mac Address',
    },

    bs_block_field_helper( { label => 2, input => 4 } )
);

has_field 'display' => (
    type  => 'Text',
    label => 'Notes',
);

has_field 'notes' => (
    type  => 'Text',
    label => 'Notes',
);

has_field 'location' => (
    type     => 'Select',
    required => 1,
    label    => 'Location',
    widget   => 'RadioGroup',
    options  => [
        {
            value => App::Manoc::DB::Result::HWAsset->LOCATION_WAREHOUSE,
            label => 'Warehouse'
        },
        {
            value => App::Manoc::DB::Result::HWAsset->LOCATION_ROOM,
            label => 'Specify'
        },
    ],
    wrapper_tags => { inline => 1 },
);

has_field 'warehouse' => (
    type         => 'Select',
    empty_select => '--- Choose ---',
    required     => 0,
    label        => 'Warehouse',
);

has_block 'location_block' => (
    render_list => [ 'building', 'room', 'floor' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_field 'building' => (
    type         => 'Select',
    empty_select => '--- Choose ---',
    required     => 0,
    label        => 'Building',
    do_wrapper   => 0,
    tags         => {
        before_element => '<div class="col-sm-4">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-2'],
);

has_field 'floor' => (
    type  => 'Text',
    label => 'Floor',
    size  => 4,

    do_wrapper => 0,
    tags       => {
        before_element => '<div class="col-sm-2">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-1'],
);

has_field 'room' => (
    type       => 'Text',
    label      => 'Room',
    size       => 16,
    do_wrapper => 0,
    tags       => {
        before_element => '<div class="col-sm-2">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-1'],
);

sub default_location {
    my $self = shift;
    my $item = $self->item;

    return unless $item;

    $item->is_in_warehouse and return DB::HWAsset->LOCATION_WAREHOUSE;
    return DB::HWAsset->LOCATION_ROOM;
}

sub options_building {
    my $self = shift;
    return unless $self->schema;
    my @buildings =
        $self->schema->resultset('Building')->search( {}, { order_by => 'name' } )->all();
    my @selections;
    foreach my $b (@buildings) {
        my $option = {
            label => $b->label,
            value => $b->id
        };
        push @selections, $option;
    }
    return @selections;
}

sub options_warehouse {
    my $self = shift;
    return unless $self->schema;
    my @warehouses =
        $self->schema->resultset('Warehouse')->search( {}, { order_by => 'name' } )->all();

    my @selections;
    foreach my $b (@warehouses) {
        my $option = {
            label => $b->label,
            value => $b->id
        };
        push @selections, $option;
    }
    return @selections;
}

before 'validate_form' => sub {
    my $self     = shift;
    my $params   = $self->params;
    my $location = $params->{location};

    my @required;
    if ( $location eq DB::HWAsset->LOCATION_ROOM ) {
        push @required, 'building';
    }

    foreach (@required) {
        my $field = $self->field($_);
        next unless $field && !$field->required;
        $self->add_required($field);    # save for clearing later.
        $field->required(1);
    }
};

sub update_model_location {
    my $self     = shift;
    my $values   = $self->value;
    my $item     = $self->item;
    my $location = $values->{location};

    if ( $location eq DB::HWAsset->LOCATION_WAREHOUSE ) {
        $item->move_to_warehouse( $values->{warehouse} );
    }
    elsif ( $location eq DB::HWAsset->LOCATION_ROOM ) {
        $item->move_to_room( $values->{building}, $values->{floor}, $values->{room} );
    }
    else {
        # unknown value, do nothing
        return;
    }

    delete $values->{warehouse};
    delete $values->{location};
    delete $values->{building};
    delete $values->{floor};
    delete $values->{room};

    $self->_set_value($values);
}

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
        my $field_error = $field->get_message('unique') ||
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
        $values->{location} = App::Manoc::DB::Result::HWAsset->LOCATION_WAREHOUSE;
    $self->_set_value($values);
    $self->update_model_location();

    super();
};

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
