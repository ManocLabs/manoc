# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Netwalker::Source;
use Moose::Role;

requires 'connect';

requires 'neighbors';
requires 'device_info';
requires 'boottime'

requires 'ifstatus_table';
requires 'mat';

requires 'vtp_domain';
requires 'vtp_database';

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
