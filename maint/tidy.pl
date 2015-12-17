#!perl
use strict;
use warnings;

use Git::Wrapper;
use File::Copy;

-f "lib/Manoc.pm" or die "This script should be called in project root dir";
-f ".perltidyrc" or die "Missing perltidy file";


my $git = Git::Wrapper->new('.');


my @source_files = grep {  /\.p[lm]$/o } $git->ls_files;

foreach my $file (@source_files) {

    my $tidyfile = $file . '.tdy';
    print "Tidying $file\n";
    if ( my $pid = fork() ) {
	waitpid $pid, 0;
	print STDERR "Child exited with nonzero status $? "
	    if $? > 0;
	File::Copy::move( $tidyfile, $file );
	next;
    }

    exec "perltidy", "-nse", "-nst", $file, "-o", $tidyfile;
    exit 0;
}


