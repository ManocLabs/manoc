# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::Report::GenericInfo;
use Moose;
use MooseX::Storage;

our $VERSION = '0.01';

extends 'Manoc::Report';

has 'racks'   => ( is => 'rw', isa => 'Int' );
has 'devices' => ( is => 'rw', isa => 'Int' );
has 'ifaces'  => ( is => 'rw', isa => 'Int' );
has 'cdps'    => ( is => 'rw', isa => 'Int' );
has 'mats'    => ( is => 'rw', isa => 'Int' );
has 'arps'    => ( is => 'rw', isa => 'Int' );

1;
