# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::IPNetwork;

use HTML::FormHandler::Moose;
extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::SaveButton';
with 'Manoc::Form::TraitFor::Horizontal';

use namespace::autoclean;
use HTML::FormHandler::Types ('IPAddress');

has '+name' => ( default => 'form-ipnetwork' );
has '+html_prefix' => ( default => 1 );

has '+item_class' => (
    default => 'IPNetwork'
);

sub build_render_list {
    [
        'network_block', 'name', 'vlan_id', 'description', 'save',
        'csrf_token'
    ]
}

has_block 'network_block' => (
    render_list => ['address', 'prefix'],
    tag => 'div',
    class => [ 'form-group' ],
);

has_field 'address' => (
    apply => [ IPAddress ],
    size => 15,
    required => 1,
    label    => 'Address',
    do_wrapper => 0,

    # we set wrapper=>0 so we don't have the inner div too!
    tags => {
        before_element => '<div class="col-sm-6">' , after_element => '</div>'
    },
    label_class =>  [ 'col-sm-2' ],
    element_attr => { placeholder => 'IP Address' }
);

has_field 'prefix' => (
    type => 'Integer',
    required => 1,
    size     => 2,
    label    => 'Prefix',
    do_wrapper => 0,
    tags => {
        before_element => '<div class="col-sm-2">' , after_element => '</div>'
    },
    label_class =>  [ 'col-sm-2' ],
    element_attr => { placeholder => '24' }
);

has_field 'name' => (
    type => 'Text',
    required => 1,
    label => 'Name',
    element_attr => { placeholder => 'Network name' }
);

has_field 'vlan_id' => (
    type => 'Select',
    label => 'Vlan',
    empty_select => '---Choose a VLAN---',
);

has_field 'description' => (
    type => 'TextArea',
    label => 'Description',
);

sub options_vlan_id {
    my $self = shift;

    return unless $self->schema;
    my $rs = $self->schema->resultset('Vlan')->search( {}, { order_by => 'id' } );
    return map +{ value => $_->id, label => $_->name . " (" . $_->id . ")" }, $rs->all();
}


override validate_model => sub {
    my $self  = shift;
    my $item  = $self->item;

    $item->is_larger_than_parent and
        $self->add_form_error('A network cannot be larger than its parent');

    $item->is_smaller_than_children and
        $self->add_form_error('A network cannot be smaller than its children');

    super();
};

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;
1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
