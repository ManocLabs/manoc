package App::Manoc::Form::VirtualMachine;
use HTML::FormHandler::Moose;

##VERSION

use namespace::autoclean;

extends 'App::Manoc::Form::BaseDBIC';
with
    'App::Manoc::Form::TraitFor::SaveButton',
    'App::Manoc::Form::TraitFor::Horizontal';

use App::Manoc::Form::Types ('MacAddress');

use App::Manoc::Form::Helper qw/bs_block_field_helper/;

has '+name'        => ( default => 'form-virtualmachine' );
has '+html_prefix' => ( default => 1 );

has '+item_class' => ( default => 'VirtualMachine' );

sub build_render_list {
    return [
        qw/
            name identifier
            resources_block
            hyper_block

            nics

            notes

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
    type         => 'Integer',
    required     => 1,
    label        => 'RAM',
    element_attr => {
        placeholder => 'MB',
    },
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

override validate_model => sub {
    my $self   = shift;
    my $item   = $self->item;
    my $values = $self->values;

    my $found_error = super() || 0;

    $self->_validate_model_nics and $found_error++;

    return $found_error;
};

sub _validate_model_nics {
    my $self = shift;

    my $found_error = 0;
    my %nic_names;
    my %nic_addresses;

    foreach my $nic ( $self->field('nics')->fields ) {

        # validate macaddress
        my %conditions;

        my $macaddr_field = $nic->field('macaddr');
        my $macaddr       = $macaddr_field->value;
        if ( defined($macaddr) ) {
            $conditions{macaddr} = $macaddr;
            $nic->field('id')->value and
                $conditions{id} = { '!=' => $nic->field('id')->value };
            my $count = $self->schema->resultset('VServerNIC')->search( \%conditions )->count;
            if ( $count > 0 || $nic_addresses{$macaddr} ) {
                my $field_error = $macaddr_field->get_message('unique') ||
                    $macaddr_field->unique_message ||
                    'Duplicate value for [_1]';
                $macaddr_field->add_error( $field_error, $macaddr_field->loc_label );
                $found_error++;
            }

            $nic_addresses{$macaddr} = 1;
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

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
