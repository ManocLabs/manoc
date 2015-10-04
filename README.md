Manoc
=====

Manoc is a web-based network monitoring/reporting platform designed for moderate to large networks.

It's able to collect and display:

- Ports status and mac-address associations network devices via SNMP
- Ethernet/IP address pairings via a sniffer agent
- DHCP leases/reservations using a lightweight agent for ISC DHCPD based servers
- users and computer logon in a Windows AD environment, using an agent for syslog-ng to trap snare generated syslog messages

Data is stored using a SQL database for scalability and speed. It's written in Perl using Catalyst, DBIx::Class, Moose and SNMP::Info.

See https://github.com/ManocLabs/manoc/wiki for more info.

[![Build Status](https://travis-ci.org/ManocLabs/manoc.svg?branch=master)](https://travis-ci.org/ManocLabs/manoc)
