#!/bin/sh

/vagrant/script/manoc_create_ddl.pl | mysql -u {{manoc_db_user}} -p{{manoc_db_pass}} {{manoc_db_name}}
/vagrant/script/manoc_initdb.pl
