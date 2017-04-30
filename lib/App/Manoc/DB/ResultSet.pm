# Copyright 2011-2017 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::DB::ResultSet;

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

# do not load ingnorewantarray helper since it breaks
# HTML::FormHandler

__PACKAGE__->load_components(
    qw{
        Helper::ResultSet::AutoRemoveColumns
        Helper::ResultSet::CorrelateRelationship
        Helper::ResultSet::Me
        Helper::ResultSet::NoColumns
        Helper::ResultSet::RemoveColumns
        Helper::ResultSet::ResultClassDWIM
        Helper::ResultSet::SearchOr
        Helper::ResultSet::SetOperations
        Helper::ResultSet::Shortcut
        }
);

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
