use inc::Module::Install;
name     'Manoc';
license  'Perl_5';
all_from 'lib/Manoc.pm';
author 'Gabriele Mambrini <g.mambrini@gmail.com>';

install_share 'root';
install_script "script/manoc_archiver.pl";
install_script "script/manoc_arpsniffer.pl";
install_script "script/manoc_backup.pl";
install_script "script/manoc_cgi.pl";
install_script "script/manoc_create_ddl.pl";
install_script "script/manoc_dhcp_agent.pl";
install_script "script/manoc_dump.pl";
install_script "script/manoc_fastcgi.pl";
install_script "script/manoc_initdb.pl";
install_script "script/manoc_ipagent.pl";
install_script "script/manoc_netwalker.pl";
install_script "script/manoc_server.pl";
install_script "script/manoc_snarewin_agent.pl";

resources
  homepage => 'http://manoc.info/',
    repository => 'git://github.com/ManocLabs/manoc';

# use Module::Install::CPANfile
cpanfile;

WriteAll;
