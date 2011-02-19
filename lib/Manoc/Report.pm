# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::Report;
use Moose;
use MooseX::Storage;

our $VERSION = '0.01';

with Storage( 'format' => 'YAML' );

1;
