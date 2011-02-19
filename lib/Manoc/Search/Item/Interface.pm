# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Search::Item::Interface;
use Moose;

extends 'Manoc::Search::Item';

no Moose;
__PACKAGE__->meta->make_immutable;
