use inc::Module::Install;
name     'App-Manoc';
license  'Perl_5';
all_from 'lib/App/Manoc.pm';
author 'Gabriele Mambrini <g.mambrini@gmail.com>';

install_share 'root';
install_script "script/manoc_archiver.pl";
install_script "script/manoc_arpsniffer.pl";
install_script "script/manoc_cgi.pl";
install_script "script/manoc_create_ddl.pl";
install_script "script/manoc_dump.pl";
install_script "script/manoc_fastcgi.pl";
install_script "script/manoc_initdb.pl";
install_script "script/manoc_netwalker.pl";
install_script "script/manoc_server.pl";

resources
  homepage => 'http://manoc.info/',
    repository => 'git://github.com/ManocLabs/manoc';

# use Module::Install::CPANfile
cpanfile;

tests 't/*.t t/*/*.t';

WriteAll;
