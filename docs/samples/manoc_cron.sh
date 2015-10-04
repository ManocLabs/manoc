#!/bin/sh

BASE_DIR=
LOG=$BASE_DIR/log/cron.log

echo >> $LOG
date >> $LOG
perl $BASE_DIR/script/manoc_netwalker.pl >>$LOG 2>&1
perl $BASE_DIR/script/manoc_archiver.pl  >>$LOG 2>&1
perl $BASE_DIR/script/manoc_backup.pl >>$LOG 2>&1
