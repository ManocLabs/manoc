# Copyright 2011-2017 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::ResultSet;

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('Helper::ResultSet');

sub search {
    # this is a terribile hack because HFH requires wantarray support
    # for HTML::FormHandler::InitResult
    my $caller1 = ( caller(1) )[0];
    my $caller2 = ( caller(2) )[0];

    if ( defined($caller1) && $caller1 =~ /^HTML::FormHandler/ ||
        defined($caller2) && $caller2 =~ /^HTML::FormHandler/ )
    {
        return wantarray ? shift->search(@_)->all : shift->search_rs(@_);
    }
    return shift->next::method(@_);
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
