package App::Manoc::Form::Workstation::Edit;
use HTML::FormHandler::Moose;

##VERSION

use namespace::autoclean;

extends 'App::Manoc::Form::Base';
with
    'App::Manoc::Form::TraitFor::Horizontal',
    'App::Manoc::Form::TraitFor::SaveButton',
    'App::Manoc::Form::TraitFor::IPAddr';

use HTML::FormHandler::Types ('IPAddress');

has '+item_class' => ( default => 'Workstation' );

has '+name'        => ( default => 'form-workstation' );
has '+html_prefix' => ( default => 1 );

has_field 'hostname' => (
    type         => 'Text',
    required     => 1,
    label        => 'Hostname',
    element_attr => {
        placeholder => 'hostname.local.domain',
        size        => '100%',
    },
);

has_field 'os' => (
    type         => 'Text',
    size         => 32,
    label        => 'OS Name',
    element_attr => { placeholder => 'e.g. CentOS' },
);

has_field 'os_ver' => (
    type         => 'Text',
    size         => 32,
    label        => 'Version',
    element_attr => { placeholder => 'e.g. 7.0' },
);

has_field 'ethernet_static_ipaddr' => (
    type           => 'Text',
    label          => 'Ethernet Static Address',
    apply          => [IPAddress],
    inflate_method => \&inflate_ipv4,
    element_attr   => {
        placeholder => '0.0.0.0',
        size        => '100%',
    },
);

has_field 'wireless_static_ipaddr' => (
    type           => 'Text',
    label          => 'Wireless Static Address',
    apply          => [IPAddress],
    inflate_method => \&inflate_ipv4,
    element_attr   => {
        placeholder => '0.0.0.0',
        size        => '100%',
    },
);

has_field 'workstationhw' => (
    label        => 'Hardware',
    type         => 'Select',
    label        => 'Hardware',
    empty_select => '--- Choose ---',
    tags         => {
        input_append_button              => 'Add',
        input_append_button_element_attr => {
            class => 'btn-primary',
            href  => '#',
            id    => 'form-workstation.asset_button',
        },
    },
    element_class => 'selectpicker',
    element_attr  => { 'data-live-search' => 'true' }
);

sub options_workstationhw {
    my $self = shift;

    return unless $self->schema;
    my @rs = $self->schema->resultset('WorkstationHW')->unused()->all();
    my @selections;

    if ( my $s = $self->item->workstationhw ) {
        push @selections,
            {
            label => $s->label,
            value => $s->id
            };
    }

    foreach my $b (@rs) {
        my $option = {
            label => $b->label,
            value => $b->id
        };
        push @selections, $option;
    }

    return @selections;

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
