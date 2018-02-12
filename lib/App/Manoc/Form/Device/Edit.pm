package App::Manoc::Form::Device::Edit;

use HTML::FormHandler::Moose;

##VERSION

extends 'App::Manoc::Form::BaseDBIC';
with 'App::Manoc::Form::TraitFor::SaveButton',
    'App::Manoc::Form::TraitFor::RackOptions',
    'App::Manoc::Form::TraitFor::Horizontal',
    'App::Manoc::Form::TraitFor::IPAddr';

use App::Manoc::DB::Result::HWAsset;
use HTML::FormHandler::Types ('IPAddress');

has '+name' => ( default => 'form-device' );

sub build_render_list {
    return [
        'name',        'mng_block', 'hwasset', 'rack_block',
        'lan_segment', 'notes',     'save',    'csrf_token'
    ];
}

has_field 'name' => (
    type     => 'Text',
    required => 0,
    apply    => [
        'Str',
        {
            check   => sub { $_[0] =~ /\w/ },
            message => 'Invalid name'
        },
    ]
);

has_field 'hwasset' => (
    type         => 'Select',
    label        => 'Hardware asset',
    empty_select => '--- Select asset ---',
    required     => 0,

    tags => {
        input_append_button              => 'Add',
        input_append_button_element_attr => {
            class => 'btn-primary',
            href  => '#',
            id    => 'asset_button',
        },
    },
    element_class => 'selectpicker',
    element_attr  => { 'data-live-search' => 'true' }
);

has_block 'mng_block' => (
    render_list => [ 'mng_address', 'mng_url_format' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_field 'mng_address' => (
    apply          => [IPAddress],
    label          => 'Management Address',
    required       => 1,
    element_attr   => { placeholder => 'IP Address' },
    inflate_method => \&inflate_ipv4,

    do_wrapper => 0,
    tags       => {
        before_element => '<div class="col-sm-5">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-2'],
);

has_field 'mng_url_format' => (
    type         => 'Select',
    label        => 'URL type',
    empty_select => '- None -',

    do_wrapper => 0,
    tags       => {
        before_element => '<div class="col-sm-3">',
        after_element  => '</div>'
    },
    element_class => ['selectpicker'],
    label_class   => ['col-sm-2'],
);

has_block 'rack_block' => (
    render_list => [ 'rack', 'rack_level' ],
    tag         => 'div',
    class       => ['form-group'],
);

#Location
has_field 'rack' => (
    type         => 'Select',
    label        => 'Rack',
    empty_select => '--- Select a rack ---',
    required     => 0,

    do_wrapper => 0,
    # set wrapper=>0 so we don't get the inner div

    tags => {
        before_element => '<div class="col-sm-6" >',
        after_element  => '</div>'
    },
    element_class => ['selectpicker'],
    element_attr  => { "data-live-search" => "true" },
    label_class   => ['col-sm-2'],
);

has_field 'rack_level' => (
    label      => 'Level',
    type       => 'Text',
    required   => 0,
    do_wrapper => 0,
    tags       => {
        before_element => '<div class="col-sm-2">',
        after_element  => '</div>'
    },
    label_class => ['col-sm-2'],
);

has_field 'lan_segment' => (
    type         => 'Select',
    label        => 'Lan Segment',
    empty_select => '--- Select ---',
    required     => 0,

    element_class => 'selectpicker',
);

has_field 'notes' => ( type => 'TextArea' );

sub options_mng_url_format {
    my $self = shift;
    return unless $self->schema;

    my $rs = $self->schema->resultset('MngUrlFormat')->search( {}, { order_by => 'name' } );

    return map +{ value => $_->id, label => $_->name }, $rs->all();
}

sub options_hwasset {
    my $self = shift;
    return unless $self->schema;

    my @options;
    if ( my $hwasset = $self->item->hwasset ) {
        push @options,
            {
            value => $hwasset->id,
            label => $hwasset->label,
            };
    }
    push @options,
        map +{
        value => $_->id,
        label => $_->label,
        },
        $self->schema->resultset('HWAsset')->unused_devices()->all();

    return @options;
}

sub options_rack {
    my $self = shift;

    return unless $self->schema;

    return $self->get_rack_options;
}

before update_fields => sub {
    my $self = shift;

    my $lan_segment_rs = $self->schema->resultset('LanSegment');
    if ( $lan_segment_rs->count == 1 ) {
        $self->field('lan_segment')->default( $lan_segment_rs->first->id );
    }

};

override validate_model => sub {
    my ($self) = @_;

    my $found_error = 0;
    my $rs          = $self->resultset;

    my $field;

    # validate rack: mind inactive fields

    if ( $self->field('hwasset')->is_active && $self->field('hwasset')->value ) {
        my $rack = $self->item->rack;
        $self->field('rack')->is_active and $rack = $self->field('rack')->value;

        if ( !defined($rack) ) {
            my $field_error = 'Rack is required when using hardware assets';
            $field->add_error( $field_error, $field->loc_label );
            $found_error++;
        }
    }

    return $found_error || super();
};

override update_model => sub {
    my $self = shift;

    $self->schema->txn_do(
        sub {
            my $prev_hwasset = $self->item->hwasset;
            super();

            my $device  = $self->item;
            my $hwasset = $device->hwasset;

            if ( $prev_hwasset && $prev_hwasset != $hwasset ) {
                $prev_hwasset->move_to_warehouse();
                $prev_hwasset->update();
            }
            if ($hwasset) {
                $hwasset->move_to_rack( $device->rack );
                $hwasset->update();
            }
        }
    );
};

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
