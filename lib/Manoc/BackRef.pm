package Manoc::BackRef;

# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

use Moose::Role;

sub check_backref {
    my $c       = shift;
    my $backref = $c->flash->{'backref'};
    return $backref;
}

sub set_backref {
    my $c       = shift;
    my $backref = $c->req->param('backref');
    if ($backref) {
        $c->flash( backref => $backref );
        delete $c->request->parameters->{'backref'};
    }
}

1;
