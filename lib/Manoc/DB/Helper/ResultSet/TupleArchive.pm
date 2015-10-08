# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Helper::ResultSet::TupleArchive;
use strict;
use warnings;

use Carp 'croak';

use parent 'DBIx::Class::ResultSet';

=head1 NAME

Manoc::DB::Helper::ResultSet::TupleArchive - Tuple archive support

=head1 SYNOPSIS

 # note that this is normally a component for a ResultSet
 package MySchema::ResultSet::Bar;

 use strict;
 use warnings;

 use parent 'DBIx::Class::ResultSet';

  __PACKAGE__->load_components('+Manoc::DB::Helper::ResultSet::TupleArchive');

Adds register_tuple and archive methods.

=head1 DESCRIPTION

Used for registering events in Manoc.

=head1 METHODS

=head2 register_tuple

=cut

sub register_tuple {
    my $self = shift;
    my %params = @_;

    my $tuple_columns = $self->result_class->tuple_archive_columns;

    # check params
    foreach (@$tuple_columns) {
	croak "No $_ in values" unless $params{$_};
    }
    my $timestamp = $params{timestamp} || time;
    my %tuple = map { $_ => $params{$_} } @$tuple_columns;

    my @entries = $self->search({
	%tuple,
	archived => 0,
    });

    if ( scalar(@entries) > 1 ) {
        warn "More than one non archived entry";
	return;
    }
    elsif ( scalar(@entries) == 1 ) {
        my $entry = $entries[0];
        $entry->lastseen($timestamp);
        $entry->update();
    }
    else {
        $self->create({
	    %tuple,
	    firstseen => $timestamp,
	    lastseen  => $timestamp,
	    archived  => 0
	});
    }
}

=head2 archive([ $age ])

Archive tuples with lastseen older than $age seconds. Return number of archived elements.
Age defaults to one day.

=cut

sub archive {
    my ($self, $archive_age) = @_;

    # default is one day
    $archive_age ||= 3600 * 24;

    my $archive_date = time - $archive_age;
    my $rs = $self->search({
	'archived'  => 0,
	'lastseen' => { '<', $archive_date },
    });

    my $count = $rs->count;
    $rs->update({'archived' => 1});

    return $count;
}


1;


=head1 AUTHOR

The Manoc Team

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:

