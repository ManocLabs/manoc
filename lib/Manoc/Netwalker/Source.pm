# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Netwalker::Source;
use Moose::Role;

requires 'connect';

requires 'device_info';
requires 'boottime';


has 'neighbors' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_neighbors',
);
requires '_build_neighbors';

has 'mat' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_mat',
);
requires  '_build_mat';

has 'ifstatus_table' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_ifstatus_table',
);
requires '_build_ifstatus_table';

requires 'vtp_domain';
requires 'vtp_database';

has 'arp_table' => (   
    is      => 'ro',
    lazy    => 1,
    builder => '_build_arp_table',
);
requires '_build_arp_table';


1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
