package App::Manoc::DB::ResultSet;
#ABSTRACT: base class for Manoc dbic resultset classes

use strict;
use warnings;

##VERSION

use parent 'DBIx::Class::ResultSet';

# do not load ingnorewantarray helper since it breaks
# HTML::FormHandler
#
# also avoid Helper::ResultSet::AutoRemoveColumns
__PACKAGE__->load_components(
    qw{
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
