# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::DataDumper::Converter::v3;

use Moose;
use Data::Dumper;
use Manoc::Utils qw(padded_ipaddr check_addr);
extends 'Manoc::DataDumper::Converter';

sub upgrade_users {
    my ( $self, $data ) = @_;

    foreach (@$data) {
	$_->{username} = $_->{login};
	delete $_->{login};
    }

    return scalar(@$data);
}

# delete session datas
sub upgrade_sessions {
    my ( $self, $data ) = @_;

    @$data = ();
    return 0;
}

no Moose;    # Clean up the namespace.
__PACKAGE__->meta->make_immutable();
1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
