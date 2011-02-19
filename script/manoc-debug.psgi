#!/usr/bin/env perl

use Manoc;
use Plack::Builder;

Manoc->setup_engine('PSGI');
my $app = sub { Manoc->run(@_) };

builder {
    enable 'Debug', panels => [qw(DBITrace Memory Timer Environment CatalystLog   PerlConfig Response Session)];
    $app;
};
