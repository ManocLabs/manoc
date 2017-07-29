package App::Manoc::Form::TraitFor::RackOptions;
#ABSTRACT: Role for populating rack selections

use HTML::FormHandler::Moose::Role;

##VERSION

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
            order_by => [ 'me.building_id', 'me.name' ]
        }
    );

    return map +{
        value => $_->id,
        label => $_->building ? $_->label . ' - ' . $_->building->name :
            $_->label
        },
        $racks->all();
}

no HTML::FormHandler::Moose::Role;

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
