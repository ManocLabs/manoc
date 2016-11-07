# Copyright 2016 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Form::TraitFor::RackOptions;
use HTML::FormHandler::Moose::Role;

=head1 NAME

Manoc::Form::TraitFor::RackOptions - Role for populating rack selections

=head1 METHDOS

=head2 get_rack_options

Return an array suitable for populating a Rack select menu

=cut

sub get_rack_options {
    my $self = shift;

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
        label => $_->label,
        },
        $racks->all();
}

=head1 AUTHOR

Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

no HTML::FormHandler::Moose::Role;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
