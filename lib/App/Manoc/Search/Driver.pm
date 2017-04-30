# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package App::Manoc::Search::Driver;
use Moose;

has engine => ( is => 'ro' );

no Moose;
__PACKAGE__->meta->make_immutable;
