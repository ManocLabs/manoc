use strict;
use warnings;
use Test::More;

BEGIN {
      use_ok 'Manoc::Netwalker::Config',    'netwalker config';
      use_ok 'Manoc::Netwalker::Script',    'netwalker script';
      use_ok 'Manoc::Netwalker::Scheduler', 'netwalker scheduler';
      use_ok 'Manoc::Netwalker::Control',   'netwalker control server';
      use_ok 'Manoc::Netwalker::Manager',   'netwalker task manager';           
}

done_testing();
