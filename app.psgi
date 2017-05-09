#!/usr/bin/env perl

use lib 'lib';

use Manoc;
use Plack::Builder;

builder {
    enable_if { $_[0]->{HTTP_X_FORWARDED_FOR} }
    "Plack::Middleware::ReverseProxy";
    Manoc->psgi_app;
};
