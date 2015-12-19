# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::Device;

use strict;
use warnings;
use Manoc::Utils::IPAddress qw(check_addr);
use HTML::FormHandler::Moose;

extends 'Manoc::Form::Base';
with 'Manoc::Form::TraitFor::SaveButton';

has '+name'        => ( default => 'form-device' );
has '+html_prefix' => ( default => 1 );

has_field 'mng_address' => (
    type     => 'Text',
    label    => 'IP Address',
    required => 1,
    apply    => [
        'Str',
        {
            check   => sub { check_addr( $_[0] ) },
            message => 'Invalid Ip Address'
        },
    ]
);

has_field 'name' => (
    type     => 'Text',
    required => 1,
    apply    => [
        'Str',
        {
            check   => sub { $_[0] =~ /\w/ },
            message => 'Invalid Name'
        },
    ]
);

has_field 'model' => (
    type  => 'Text',
    apply => [
        'Str',
        {
            check   => sub { $_[0] =~ /\w/ },
            message => 'Invalid Model Name'
        },
    ]
);

#Location
has_field 'rack' => (
    type         => 'Select',
    label        => 'Rack name',
    empty_select => '---Choose a Rack---',
    required     => 1,
);

has_field 'level' => (
    label    => 'Level',
    type     => 'Text',
    required => 1,
);

has_field 'notes' => ( type => 'TextArea' );

has_field 'mng_url_format' => (
    type         => 'Select',
    label        => 'Management URL',
    empty_select => '---Choose a Format---'
);

sub options_rack {
    my $self = shift;
    return unless $self->schema;

    my $racks = $self->schema->resultset('Rack')->search(
        {},
        {
            join     => 'building',
            prefetch => 'building',
            order_by => 'me.name'
        }
    );

    return map +{
        value => $_->id,
        label => "Rack " . $_->name . " (" . $_->building->name . ")"
        },
        $racks->all();
}

sub options_mng_url_format {
    my $self = shift;

    return unless $self->schema;
    my $rs = $self->schema->resultset('MngUrlFormat')->search( {}, { order_by => 'name' } );

    return map +{ value => $_->id, label => $_->name }, $rs->all();
}

=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
