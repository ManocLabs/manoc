#!/usr/bin/perl
# -*- cperl -*-
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use App::Manoc::Support;

package App::Manoc::DDLCreator;
use Moose;

use SQL::Translator;
use SQL::Translator::Diff;

extends 'App::Manoc::Script';

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

has 'diff' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0,
    default  => 0
);

has 'backend' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    lazy     => 1,
    builder  => '_build_backend',
);

sub _build_backend {
    my $self = shift;

    my $schema = $self->schema or return;

    my $name = $schema->storage->dbh->{Driver}->{Name};
    $name eq 'Pg'    and return 'PostgreSQL';
    $name eq 'mysql' and return 'MySQL';
    return $name;
}

sub run {
    my $self = shift;

    $self->diff ? $self->create_diff : $self->create_ddl;
}

sub create_diff {
    my $self = shift;

    my $dbh = $self->schema->storage->dbh;

    my $be = $self->backend;
    my $translator;

    $translator = SQL::Translator->new(
        debug       => $self->debug,
        parser      => 'DBI',
        parser_args => {
            dbh => $dbh,
        },
    );
    $translator->translate();
    my $source_schema = $translator->schema or die SQL::Translator->error;
    $source_schema->name("Current");

    $translator = SQL::Translator->new(
        debug       => $self->debug,
        parser      => 'SQL::Translator::Parser::DBIx::Class',
        parser_args => { dbic_schema => $self->schema, },
    );
    $translator->producer($be);
    my $expected_sql = $translator->translate();

    $translator = SQL::Translator->new(
        debug  => $self->debug,
        parser => $be,
        data   => \$expected_sql,
    );
    $translator->translate();
    my $target_schema = $translator->schema or die SQL::Translator->error;
    $target_schema->name("New");

    my $diff = SQL::Translator::Diff->new(
        {
            output_db     => $be,
            source_schema => $source_schema,
            target_schema => $target_schema,
            debug         => $self->debug,

            ignore_index_names      => 1,
            ignore_constraint_names => 1,
        }
    )->compute_differences->produce_diff_sql;

    print $diff;
}

sub create_ddl {
    my $self = shift;

    my $translator = SQL::Translator->new(
        debug          => $self->debug,
        no_comments    => !$self->comments,
        show_warnings  => $self->show_warnings,
        add_drop_table => $self->add_drop_table,
        validate       => $self->validate,
        parser_args    => { dbic_schema => 'App::Manoc::DB', },
    );

    $translator->parser('SQL::Translator::Parser::DBIx::Class');

    my $be = $self->backend;
    $translator->producer($be);

    my $output = $translator->translate() or die "Error: " . $translator->error;

    print $output;
    return 0;
}

no Moose;

package main;

my $app = App::Manoc::DDLCreator->new_with_options();
$app->run;
