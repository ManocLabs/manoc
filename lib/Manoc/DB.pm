# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

use strict;
use warnings;

package Manoc::DB;

$__PACKAGE__::version = '20121115';

use base qw/DBIx::Class::Schema/;
__PACKAGE__->load_namespaces();

sub get_version {
    return $__PACKAGE__::version;
}

1;
