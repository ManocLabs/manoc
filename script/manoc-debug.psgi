#!/usr/bin/env perl

use App::Manoc;
use Plack::Builder;

builder {
    enable 'Debug', panels =>
        [ 
	 [ 'DBIProfile', profile => 2 ],
	 qw(Memory Timer Environment CatalystLog   PerlConfig Response Session)
        ];
    App::Manoc->psgi_app;
};
