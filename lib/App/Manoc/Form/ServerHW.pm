package App::Manoc::Form::ServerHW;

use HTML::FormHandler::Moose;

##VERSION

use namespace::autoclean;

extends 'App::Manoc::Form::Base';
with 'App::Manoc::Form::TraitFor::Horizontal',
    'App::Manoc::Form::HWAsset::Location',
    'App::Manoc::Form::TraitFor::SaveButton',
    'App::Manoc::Form::TraitFor::IPAddr';

use HTML::FormHandler::Types ('IPAddress');
use App::Manoc::Form::Types  ('MacAddress');
use App::Manoc::DB::Result::HWAsset;

has '+item_class'  => ( default => 'ServerHW' );
has '+name'        => ( default => 'form-serverhw' );
has '+html_prefix' => ( default => 1 );

has hide_location => (
    isa     => 'Bool',
    is      => 'rw',
    default => 0,
);

has_block 'processor_block1' => (
    render_list => [ 'cpu_model', 'proc_freq' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_block 'processor_block2' => (
    render_list => [ 'n_procs', 'n_cores_proc' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_field 'nics' => (
    type   => 'Repeatable',
    widget => '+App::Manoc::Form::Widget::Repeatable',
);

has_field 'nics.id' => (
    type       => 'PrimaryKey',
    do_wrapper => 0,
);

has_field 'nics.name' => (
    type         => 'Text',
    element_attr => {
        placeholder => 'name',
    },

    label => 'NIC',

    do_wrapper => 0,
    tags       => {
        before_element => '<div class="col-sm-3">',
        after_element  => '</div>'
    }
);

has_field 'nics.macaddr' => (
    type         => 'Text',
    apply        => [MacAddress],
    element_attr => {
        placeholder => '00:00:00:00:00:00',
    },

    do_label => 0,

    do_wrapper => 0,
    tags       => {
        before_element => '<div class="col-sm-3">',
        after_element  => '</div>'
    }
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

        'processor_block1', 'processor_block2',
        'ram_memory',
        'storage1_size', 'storage2_size',

        'nics',

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

    # avoid update_model called for field validation!
    validate_method => sub { },
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
        before_element => '<div class="col-sm-4">',
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
        before_element => '<div class="col-sm-4">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-2'],
);

has_field 'n_procs' => (
    type  => 'Integer',
    label => 'Num CPUs',

    do_wrapper => 0,
    # we set wrapper=>0 so we don't have the inner div too!
    tags => {
        before_element => '<div class="col-sm-4">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-2'],
);

has_field 'n_cores_proc' => (
    type  => 'Integer',
    label => 'Core per proc.',

    do_wrapper => 0,
    # we set wrapper=>0 so we don't have the inner div too!
    tags => {
        before_element => '<div class="col-sm-3">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-3'],
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
    label        => 'Secondary storage',
    element_attr => { placeholder => 'GB' },
);

has_field 'notes' => (
    type  => 'Text',
    label => 'Notes',
);

override validate_model => sub {
    my $self = shift;

    my $found_error = super() || 0;

    $self->_validate_inventory  and $found_error++;
    $self->_validate_model_nics and $found_error++;

    return $found_error;
};

sub _validate_inventory {
    my $self = shift;
    my $item = $self->item;

    my $field = $self->field('inventory');
    return if $field->has_errors;

    my $value = $field->value;
    return unless defined $value;

    my $rs = $self->schema->resultset('HWAsset');
    my $unique_filter = { inventory => $value };
    $item->id and $unique_filter->{id} = { '!=' => $item->id };
    my $count = $rs->search($unique_filter)->count;

    if ( $count > 0 ) {
        my $field_error = $field->get_message('unique') ||
            $field->unique_message ||
            'Duplicate value for [_1]';
        $field->add_error( $field_error, $field->loc_label );
        return 1;
    }

}

sub _validate_model_nics {
    my $self = shift;

    my $found_error = 0;
    my %nic_names;

    foreach my $nic ( $self->field('nics')->fields ) {
        # validate macaddress
        my %conditions;

        my $macaddr_field = $nic->field('macaddr');
        my $macaddr       = $macaddr_field->value;
        if ( defined($macaddr) ) {
            $conditions{macaddr} = $macaddr;
            $nic->field('id')->value and
                $conditions{id} = { '!=' => $nic->field('id')->value };
            my $count = $self->schema->resultset('HWServerNIC')->search( \%conditions )->count;
            if ( $count > 0 ) {
                my $field_error = $macaddr_field->get_message('unique') ||
                    $macaddr_field->unique_message ||
                    'Duplicate value for [_1]';
                $macaddr_field->add_error( $field_error, $macaddr_field->loc_label );
                $found_error++;
            }
        }

        # validate names (unique for each server)
        my $name_field = $nic->field('name');
        my $nic_name   = $name_field->value;
        if ( $nic_name && $nic_names{$nic_name} ) {
            # it's a dup!
            my $field_error = $name_field->get_message('unique') ||
                $name_field->unique_message ||
                'Duplicate value for [_1]';
            $name_field->add_error( $field_error, $name_field->loc_label );
            $found_error++;
        }
        $nic_name and $nic_names{$nic_name} = 1;
    }

    return $found_error;
}

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
