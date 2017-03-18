# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::QueryType;
use Moose::Util::TypeConstraints;

@Manoc::Search::QueryType::TYPES =
    qw(inventory building rack device server logon ipaddr macaddr note subnet);

enum 'QueryType' => \@Manoc::Search::QueryType::TYPES;

no Moose::Util::TypeConstraints;
