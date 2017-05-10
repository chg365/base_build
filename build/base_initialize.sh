#!/bin/bash

curr_dir=$(cd "$(dirname "$0")"; pwd);

base_define_file=$curr_dir/base_define.sh

if [ ! -f $base_define_file ]; then
    echo "can't find base_define.sh";
    exit 1;
fi

. $base_define_file

#if [ "$USER" != "root" ]; then
if [ `whoami` != "root" ]; then
    sudo su
    if [ "$?" != 0 ]; then
        echo "No sudo permissions.";
        return;
    fi
fi

##################################################################
#                         LOG DIR                                #
##################################################################

mkdir -p $NGINX_LOG_DIR $LOG_DIR/php-fpm

chown -R nobody:nobody $LOG_DIR

##################################################################
#                         RUN DIR                                #
##################################################################

mkdir -p $BASE_DIR/run/nginx

chown -R nobody:nobody $BASE_DIR/run
##################################################################
#                         DATA DIR                               #
##################################################################

mkdir -p $DATA_DIR/cache/php

mkdir $DATA_DIR/{sqlite3,preview}

mkdir $DATA_DIR/preview/{flash,pdf,office,txt,html}

chown -R nobody:nobody $DATA_DIR/{sqlite3,preview}

chown -R nobody:nobody $UPLOAD_TMP_DIR

##################################################################
#                         php cache file                         #
##################################################################

#$BASE_DIR/bin/init_php_cache.php
##################################################################
#                         mysql init                             #
##################################################################

if [ -f "$mysql_cnf" ]; then
    ${curr_dir}/mysql_init.sh
fi