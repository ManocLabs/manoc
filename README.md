# NAME

App::Manoc - Network monitoring application

# VERSION

version 2.99.3

# SYNOPSIS

    script/manoc_server.pl

# DESCRIPTION

Manoc is a web-based network monitoring/reporting platform designed for moderate to large networks.

Manoc collects and displays:

- Ports status and mac-address associations network devices via SNMP
- Ethernet/IP address pairings via a sniffer agenta
- DHCP leases/reservations using a lightweight agent for ISC DHCPD
based servers
- users and computer logon in a Windows AD environment, using an
agent for syslog-ng to trap snare generated syslog messages

Data is stored using a SQL database like Postgres or MySQL using DBIx::Class .

[![Build Status](https://travis-ci.org/ManocLabs/manoc.svg?branch=master)](https://travis-ci.org/ManocLabs/manoc)

# SEE ALSO

[Catalyst](https://metacpan.org/pod/Catalyst) [SNMP::Info](https://metacpan.org/pod/SNMP::Info) [Moose](https://metacpan.org/pod/Moose)

# AUTHORS

- Gabriele Mambrini <gmambro@cpan.org>
- Enrico Liguori

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gabriele Mambrini.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
