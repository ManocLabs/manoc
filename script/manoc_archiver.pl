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
use Manoc::Utils qw(str2seconds print_timestamp);

use Data::Dumper;

extends 'Manoc::Script';

has 'sources' => (
    traits   => ['NoGetopt'],
    is       => 'rw',
    isa      => 'ArrayRef[Str]',
    required => 0,
    default  => sub { [qw(Mat Arp Dot11Assoc WinLogon WinHostname)] },
);

sub archive {
    my ( $self, $time ) = @_;
    my $conf = $self->config->{'Archiver'} || $self->log->logdie("Could not find config file!");
    my $schema       = $self->schema;
    my $archive_age  = Manoc::Utils::str2seconds( $conf->{'archive_age'} );
    my $tot_archived = 0;

    if ( !$archive_age ) {
        $self->log->info("Archiver: archive_age = 0: skipping.");
        return;
    }

    $self->log->info(
        "Archiver: archiving lastseen before " . Manoc::Utils::print_timestamp($archive_date) );

    foreach my $source ( @{ $self->sources } ) {
        $self->log->debug("Archiving in table $source");
        $tot_archived = $schema->resultset($source)->archive_entries($archive_age);
    }
}

sub discard {
    my ( $self, $time ) = @_;
    my $conf = $self->config->{'Archiver'} || $self->log->logdie("Could not find config file!");
    my $discard_age   = Manoc::Utils::str2seconds( $conf->{'discard_age'} );
    my $tot_discarded = 0;

    if ( !$discard_age ) {
        $self->log->info("Archiver: discard_age = 0: skipping.");
        return;
    }

    my $discard_date = $time - $discard_age;

    $self->log->info(
        "Archiver: deleting lastseen before " . Manoc::Utils::print_timestamp($discard_date) );

    foreach my $source ( @{ $self->sources } ) {
        my $it = $self->schema->resultset($source)->search(
            {
                'archived' => 1,
                'lastseen' => { '<', $discard_date },
            }
        );
        $tot_discarded += $it->count;
        $it->delete();

    }

    my $it = $self->schema->resultset('CDPNeigh')->search(
        {
            'last_seen' => { '<', $discard_date },
        }
    );
    $tot_discarded += $it->count;
    $it->delete();
}

sub run {
    my ($self) = @_;
    my $time = time;

    $self->archive($time);
    $self->discard($time);
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
