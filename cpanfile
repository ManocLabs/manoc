# -*- mode: perl -*-

requires 'Module::Runtime';
requires 'Class::Load';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Log::Log4perl', '1.46';
requires 'DBI';
requires 'DBIx::Class';
requires 'DBIx::Class::EncodedColumn';
requires 'DBIx::Class::Tree', '0.03003';
requires 'Catalyst::Runtime', '5.90077';
requires 'Catalyst::Authentication::Credential::HTTP';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::Store::DBI';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Authentication::Store::DBIx::Class';
requires 'Catalyst::View::TT';
requires 'Catalyst::View::JSON';
requires 'Config::General';
requires 'DateTime::Format::RFC3339';
requires 'HTML::FormHandler';
requires 'HTML::FormHandler::Model::DBIC';
requires 'MooseX::Storage';
requires 'MooseX::Daemonize';
requires 'MooseX::Workers';
requires 'MooseX::Getopt';
requires 'Net::OpenSSH';
requires 'Net::NBName';
requires 'Net::SNMP';
requires 'Regexp::Common';
requires 'YAML::Syck';
requires 'Config::JFDI';
requires 'SQL::Translator';
requires 'Crypt::Eksblowfish::Bcrypt';
requires 'Plack::Middleware::ReverseProxy';
requires 'POE';
requires 'Digest::SHA1';
requires 'Archive::Tar';
requires 'Text::CSV';

on 'test' => sub {
  requires 'Test::More';
  requires 'Test::WWW::Mechanize::Catalyst', '0.60';
};

on 'develop' => sub {
  requires 'Devel::NYTProf';
  requires 'Catalyst::Devel';
  requires 'Perl::Tidy';
  requires 'Git::Wrapper';
};

feature 'arpsniffer', 'ARP sniffer support' => sub {
  requires 'Net::Pcap';
  requires 'NetPacket', '1.2.0';
};

feature 'snmp', 'SNMP::Info support' => sub {
  requires 'SNMP::Info', '3.27';
};

feature 'sqlite', 'SQLite support' => sub {
   requires 'DBD::SQLite';
};

feature 'mysql', 'MySQL support' => sub {
   requires 'DBD::mysql';
};

feature 'postgres', 'PostgreSQL support' => sub {
   requires 'DBD::Pg';
}
