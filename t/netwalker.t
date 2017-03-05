use strict;
use warnings;
use Test::More;


      use_ok 'Manoc::Netwalker::Config',    'netwalker config';
      use_ok 'Manoc::Netwalker::Script',    'netwalker script';
      use_ok 'Manoc::Netwalker::Scheduler', 'netwalker scheduler';
      use_ok 'Manoc::Netwalker::Control',   'netwalker control server';

      use_ok 'Manoc::Netwalker::Poller::Workers',     'netwalker poller task manager';
      use_ok 'Manoc::Netwalker::Poller::DeviceTask',  'netwalker poller device task';
      use_ok 'Manoc::Netwalker::Poller::ServerTask',  'netwalker poller server task';

      use_ok 'Manoc::Netwalker::Discover::Workers',  'netwalker autodiscover task manager';
      use_ok 'Manoc::Netwalker::Discover::Task',     'netwalker autodiscover task';


done_testing();
