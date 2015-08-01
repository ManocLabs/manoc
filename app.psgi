#!/usr/bin/env perl

use Manoc;
use Plack::Builder;

builder {
    Manoc->psgi_app;
};
