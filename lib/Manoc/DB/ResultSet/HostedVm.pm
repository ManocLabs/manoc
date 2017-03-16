# Copyright 2017- by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::ResultSet::HostedVm;

use base 'DBIx::Class::ResultSet';
use strict;
use warnings;

__PACKAGE__->load_components(
    qw/
        +Manoc::DB::Helper::ResultSet::TupleArchive
        /
);

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
