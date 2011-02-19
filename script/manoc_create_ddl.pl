#!/usr/bin/perl
# -*- cperl -*-
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Manoc::Support;

package Manoc::DDLCreator;
use Moose;

use Manoc::DB;
use SQL::Translator;

with 'MooseX::Getopt::Dashes';

has 'debug' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0,
    default  => 0
);

has 'trace' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0,
    default  => 0
);

has 'comments' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0,
    default  => 0
);

has 'show_warnings' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0,
    default  => 1
);

has 'add_drop_table' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0,
    default  => 0
);

has 'validate' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0,
    default  => 0
);

has 'backend' => ( is => 'rw', isa => 'Str', required => 1 );

sub run {
    my $self = shift;

    my $translator = SQL::Translator->new(
        debug          => $self->debug,
        trace          => $self->trace,
        no_comments    => !$self->comments,
        show_warnings  => $self->show_warnings,
        add_drop_table => $self->add_drop_table,
        validate       => $self->validate,
        parser_args    => { 'DBIx::Schema' => 'Manoc::DB', },
    );

    $translator->parser('SQL::Translator::Parser::DBIx::Class');

    my $be = $self->backend;
    $translator->producer("SQL::Translator::Producer::$be");

    my $output = $translator->translate() or die "Error: " . $translator->error;

    print $output;
    return 0;
}

no Moose;

package main;

my $app = Manoc::DDLCreator->new_with_options();
$app->run;
