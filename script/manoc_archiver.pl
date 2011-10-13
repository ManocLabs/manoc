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
use Manoc::Report::ArchiveReport;

use Data::Dumper;

extends 'Manoc::App';

has 'sources' => (
    traits  => [ 'NoGetopt' ],
    is => 'rw', 
    isa => 'ArrayRef[Str]', 
    required => 0, 
    default => sub { [qw(Mat Arp Dot11Assoc WinLogon WinHostname)] }, 
   );

has 'report' => (
    traits   => ['NoGetopt'],
    is       => 'rw',
    isa      => 'Manoc::Report::ArchiveReport',
    required => 0,
    default  => sub { Manoc::Report::ArchiveReport->new },
);

sub archive {
    my ($self, $time) = @_;
    my $conf         = $self->config->{'Archiver'} || $self->log->logdie("Could not find config file!") ;
    my $schema       = $self->schema;
    my $archive_age  = Manoc::Utils::str2seconds($conf->{'archive_age'}); 
    my $tot_archived = 0;

   if (! $archive_age) {
	$self->log->info("Archiver: archive_age = 0: skipping.");
        $self->report->add_error({ type   =>'archive',
                                   message => 'archive_age = 0: skipping'});
	return;
    }
    my $archive_date = $time - $archive_age;
    
    $self->log->info("Archiver: archiving lastseen before " .
		  Manoc::Utils::print_timestamp($archive_date));
    $self->report->archive_date(Manoc::Utils::print_timestamp($archive_date));

    foreach my $source ( @{$self->sources} ) {
        $self->log->debug("Archiving in table $source");
       
        my $it = $schema->resultset($source)->search({
            'archived'  => 0,
            'lastseen' => { '<', $archive_date },	    
	});
        $self->report->add_archived({source => $source,
                                     n_archived => $it->count});
        $tot_archived += $it->count;
        $it->update({'archived' => 1});
    }
    $self->report->tot_archived($tot_archived);
}


sub discard {
    my ($self, $time) = @_;
    my $conf         = $self->config->{'Archiver'} || $self->log->logdie("Could not find config file!");
    my $discard_age  = Manoc::Utils::str2seconds($conf->{'discard_age'}); 
    my $tot_discarded = 0;

    if ( ! $discard_age ) {
	$self->log->info("Archiver: discard_age = 0: skipping.");
        $self->report->add_error({ type   =>'discard',
                                   message => 'discard_age = 0: skipping'});
	return;
    }

    my $discard_date = $time - $discard_age;

    $self->log->info("Archiver: deleting lastseen before " .
		  Manoc::Utils::print_timestamp($discard_date));
    $self->report->discard_date(Manoc::Utils::print_timestamp($discard_date));

    foreach my $source ( @{$self->sources} ) {
	my $it = $self->schema->resultset($source)->search({
	    'archived'  => 1,
	    'lastseen' => { '<', $discard_date },	    
	});
        $self->report->add_discarded({source      => $source,
                                      n_discarded => $it->count});
        $tot_discarded += $it->count;
        $it->delete();
    
    }

    my $it = $self->schema->resultset('CDPNeigh')->search({
	'last_seen' => { '<', $discard_date },	    
    });
    $self->report->add_discarded({source      => 'CDPNeigh',
                                 n_discarded => $it->count});
    $tot_discarded += $it->count;
    $it->delete();
   
    $self->report->tot_discarded($tot_discarded);
}



sub discard_reports {
    my ($self, $time) = @_;
    my $conf         = $self->config->{'Archiver'} || $self->log->logdie("Could not find config file!");
    my $discard_age  = Manoc::Utils::str2seconds($conf->{'reports_age'}); 
    my $tot_discarded = 0;

    if ( ! $discard_age ) {
	$self->log->info("Archiver: reports_age = 0: skipping.");
        $self->report->add_error({ type   =>'report',
                                   message => 'reports_age = 0: skipping'});
	return;
    }

    my $discard_date = $time - $discard_age;

    $self->log->info("Archiver: deleting reports before " .
		  Manoc::Utils::print_timestamp($discard_date));
    $self->report->reports_date(Manoc::Utils::print_timestamp($discard_date));

    my $it = $self->schema->resultset('ReportArchive')->search({
                                                                'timestamp' => { '<', $discard_date },	    
                                                               });
    $self->report->add_discarded({source      => 'ReportArchive',
                                      n_discarded => $it->count});
    $tot_discarded += $it->count;
    $it->delete();
    

    $self->report->tot_discarded($tot_discarded);

}


sub run {
    my ($self) = @_;
    my $time = time;

    $self->archive($time);
    $self->discard($time);

    $self->discard_reports($time);

    $self->schema->resultset('ReportArchive')->create(
        {
            'timestamp' => time,
	    'name'      => 'archive report',
	    'type'      => 'ArchiveReport',
            's_class'   => $self->report,
        }
    );
  $self->log->debug(Dumper($self->report));
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
