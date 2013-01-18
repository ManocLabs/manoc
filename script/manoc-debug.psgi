#!/usr/bin/env perl

use Manoc;
use Plack::Builder;

builder {
    enable 'Debug', panels => [qw(DBITrace Memory Timer Environment CatalystLog   PerlConfig Response Session)];
    Manoc->psgi_app;
};
