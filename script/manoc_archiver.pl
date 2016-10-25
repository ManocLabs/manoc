#!/usr/bin/perl
# -*- cperl -*-
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Manoc::Support;

package Manoc::Archiver;
use Moose;
use Manoc::Logger;
use Manoc::Utils::Datetime qw(str2seconds print_timestamp);

use Data::Dumper;

extends 'Manoc::Script';

sub archive {
    my ( $self, $time ) = @_;
    my $conf = $self->config->{'Archiver'} || $self->log->logdie("Could not find config file!");
    my $schema = $self->schema;

    my $archive_age = str2seconds( $conf->{'archive_age'} );
    my $discard_age = str2seconds( $conf->{'discard_age'} );

    my $tot_discarded = 0;
    my $tot_archived  = 0;

    if ($archive_age) {
        $self->log->info(
            "Archiver: archiving lastseen befor " . print_timestamp( $time - $archive_age ) );
    }

    my $discard_date;
    if ($discard_age) {
        $discard_date = $time - $discard_age;
        $self->log->info(
            "Archiver: deleting lastseen before " . print_timestamp($discard_date) );
    }

    my @source_names = $schema->sources;
    foreach my $source (@source_names) {
        my $rs = $schema->resultset($source);
        $rs->can('archive') or next;

        $self->log->debug("Table $source supports archiving");

        if ($archive_age) {
            $tot_archived += $schema->resultset($source)->archive($archive_age);
        }

        if ($discard_age) {
            my $it = $self->schema->resultset($source)->search(
                {
                    'archived' => 1,
                    'lastseen' => { '<', $discard_date },
                }
            );
            $tot_discarded += $it->count;
            $it->delete();
        }
    }

    if ($discard_age) {
        my $cdp = $self->schema->resultset('CDPNeigh')
            ->search( 'last_seen' => { '<', $discard_date } );
        $tot_discarded += $cdp->count;
        $cdp->delete();
    }

    $self->log->info("Archived $tot_archived entries");
    $self->log->info("Deleted $tot_discarded entries");
}

sub run {
    my ($self) = @_;
    my $time = time;

    $self->archive($time);
}

no Moose;

package main;

my $app = Manoc::Archiver->new_with_options();
$app->run();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-indent-parens-as-block: t
# End:
