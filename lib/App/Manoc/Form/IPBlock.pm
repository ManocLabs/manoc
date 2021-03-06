package App::Manoc::Form::IPBlock;

use HTML::FormHandler::Moose;

##VERSION

use namespace::autoclean;

extends 'App::Manoc::Form::BaseDBIC';
with 'App::Manoc::Form::TraitFor::Horizontal',
    'App::Manoc::Form::TraitFor::SaveButton',
    'App::Manoc::Form::TraitFor::IPAddr';

use HTML::FormHandler::Types ('IPAddress');

has '+name' => ( default => 'form-ipnetwork' );

has '+item_class' => ( default => 'IPBlock' );

sub build_render_list {
    [ 'name', 'range_block', 'description', 'save', 'csrf_token', ];
}

has_block 'range_block' => (
    render_list => [ 'from_addr', 'to_addr' ],
    tag         => 'div',
    class       => ['form-group'],
);

has_field 'from_addr' => (
    apply          => [IPAddress],
    size           => 15,
    required       => 1,
    label          => 'From',
    inflate_method => \&inflate_ipv4,

    do_wrapper => 0,
    # we set wrapper=>0 so we don't have the inner div too!
    tags => {
        before_element => '<div class="col-sm-4">',
        after_element  => '</div>'
    },
    label_class  => ['col-sm-2'],
    element_attr => { placeholder => 'IP Address' }
);

has_field 'to_addr' => (
    apply          => [IPAddress],
    size           => 15,
    required       => 1,
    label          => 'To',
    inflate_method => \&inflate_ipv4,

    do_wrapper => 0,
    # we set wrapper=>0 so we don't have the inner div too!
    tags => {
        before_element => '<div class="col-sm-4">',
        after_element  => '</div>'
    },
    label_class  => ['col-sm-2'],
    element_attr => { placeholder => 'IP Address' }
);

has_field 'name' => (
    type         => 'Text',
    required     => 1,
    label        => 'Name',
    element_attr => { placeholder => 'Block name' }
);

has_field 'description' => (
    type  => 'TextArea',
    label => 'Description',
);

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
