# This file is generated by Dist::Zilla::Plugin::CPANFile v6.024
# Do not edit this file directly. To change prereqs, edit the `dist.ini` file.

requires "Archive::Tar" => "2.32";
requires "Catalyst::Action::RenderView" => "0.16";
requires "Catalyst::Authentication::Credential::HTTP" => "1.018";
requires "Catalyst::Authentication::Store::DBIx::Class" => "0.1506";
requires "Catalyst::Plugin::ConfigLoader" => "0.34";
requires "Catalyst::Plugin::Session" => "0.41";
requires "Catalyst::Plugin::Session::State::Cookie" => "0.17";
requires "Catalyst::Plugin::Session::Store::DBI" => "0.16";
requires "Catalyst::Plugin::StackTrace" => "0.12";
requires "Catalyst::Plugin::Static::Simple" => "0.35";
requires "Catalyst::Runtime" => "5.90123";
requires "Catalyst::View::CSV" => "1.7";
requires "Catalyst::View::JSON" => "0.36";
requires "Catalyst::View::TT" => "0.44";
requires "Class::Load" => "0.24";
requires "Config::General" => "2.63";
requires "Config::ZOMG" => "1.0";
requires "Crypt::Eksblowfish::Bcrypt" => "0.009";
requires "DBD::SQLite" => "1.58";
requires "DBI" => "1.641";
requires "DBIx::Class" => "0.082841";
requires "DBIx::Class::EncodedColumn" => "0.00015";
requires "DBIx::Class::Helpers" => "2.033004";
requires "DBIx::Class::Tree" => "0.03003";
requires "DateTime::Format::RFC3339" => "v1.2.0";
requires "Digest::SHA1" => "2.13";
requires "HTML::FormHandler" => "0.40068";
requires "HTML::FormHandler::Model::DBIC" => "0.29";
requires "JSON" => "4.05";
requires "Log::Log4perl" => "1.49";
requires "Module::Runtime" => "0.015";
requires "Moose" => "2.2011";
requires "MooseX::Daemonize" => "0.21";
requires "MooseX::Getopt" => "0.72";
requires "MooseX::Storage" => "0.52";
requires "MooseX::Workers" => "0.24";
requires "Net::NBName" => "0.26";
requires "Net::OpenSSH" => "0.77";
requires "Net::SNMP" => "v6.0.1";
requires "POE" => "1.370";
requires "Plack::Middleware::ReverseProxy" => "0.15";
requires "Regexp::Common" => "2017060201";
requires "SQL::Translator" => "0.11024";
requires "Test::Deep" => "1.128";
requires "Text::CSV" => "1.97";
requires "YAML::Syck" => "1.30";
requires "namespace::autoclean" => "0.28";
recommends "Net::Pcap" => "0";
recommends "NetPacket" => "0";
recommends "SNMP::Info" => "3.27";
suggests "DBD::Pg" => "v3.7.4";
suggests "DBD::mysql" => "4.046";

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0";
  requires "Test::WWW::Mechanize::Catalyst" => "0.60";
};

on 'configure' => sub {
  requires "CPAN::Meta::Requirements" => "2.120620";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::ShareDir::Install" => "0.06";
  requires "Module::Metadata" => "0";
};

on 'develop' => sub {
  requires "Catalyst::Devel" => "0";
  requires "DBD::Pg" => "v3.7.4";
  requires "DBD::mysql" => "4.046";
  requires "Dist::Zilla" => "0";
  requires "Git::Wrapper" => "0";
  requires "Perl::Tidy" => "0";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::EOL" => "0";
  requires "Test::Kwalitee" => "1.21";
  requires "Test::More" => "0.88";
  requires "Test::NoTabs" => "0";
  requires "Test::Perl::Critic" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Version" => "1";
};
