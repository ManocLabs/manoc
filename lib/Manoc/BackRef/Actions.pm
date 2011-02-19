# Copyright 2011 by the Manoc Team
#
# This library is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.

package Manoc::BackRef::Actions;

use Moose::Role;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

before 'auto' => sub {
    my ( $self, $c ) = @_;

    $c->set_backref($c);
};

sub follow_backref : Private {
    my ( $self, $c ) = @_;

    my $backref = $c->check_backref($c);
    $backref ||= $c->stash->{default_backref};

    $c->response->redirect($backref);
}

1;
