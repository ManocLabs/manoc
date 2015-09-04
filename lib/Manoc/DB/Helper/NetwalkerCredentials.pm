# Copyright 2011-2015 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
package Manoc::DB::Helper::NetwalkerCredentials;
use strict;
use warnings;

sub make_credentials_columns {
    my $self = shift;

    $self->add_columns(
	username => {
	    data_type     => 'varchar',
	    size          => 64,
	    default_value => 'NULL',
	    is_nullable   => 1,
	},
	password => {
	    data_type     => 'varchar',
	    size          => 64,
	    default_value => 'NULL',
	    is_nullable   => 1,
	},
	password2 => {
	    data_type     => 'varchar',
	    size          => 64,
	    default_value => 'NULL',
	    is_nullable   => 1,
	},

	snmp_community => {
	    data_type     => 'varchar',
	    size          => 64,
	    default_value => 'NULL',
	    is_nullable   => 1,
	},
	snmp_user => {
	    data_type     => 'varchar',
	    size          => 50,
	    default_value => 'NULL',
	    is_nullable   => 1,
	},
	snmp_password => {
	    data_type     => 'varchar',
	    size          => 50,
	    default_value => 'NULL',
	    is_nullable   => 1,
	},
	snmp_ver => {
	    data_type     => 'int',
	    size          => 1,
	    default_value => '0',
	},
    );
}

1;
