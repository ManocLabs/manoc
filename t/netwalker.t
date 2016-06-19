use strict;
use warnings;
use Test::More;

BEGIN {
      use_ok 'Manoc::Netwalker::Config',    'netwalker config';
      use_ok 'Manoc::Netwalker::Script',    'netwalker script';
      use_ok 'Manoc::Netwalker::Scheduler', 'netwalker scheduler';
      use_ok 'Manoc::Netwalker::Control',   'netwalker control server';

      use_ok 'Manoc::Netwalker::Manager::Device',   'netwalker device task manager';
      use_ok 'Manoc::Netwalker::Manager::Discover',   'netwalker autodiscover task manager';

      use_ok 'Manoc::Netwalker::DeviceTask',   'netwalker device task';
      use_ok 'Manoc::Netwalker::DiscoverTask',   'netwalker autodiscover task';
}

done_testing();
