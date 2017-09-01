#!/bin/bash

user="chg"
group="chg"

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

grep -q "^${group}:" /etc/group
if [ "$?" != 0 ]; then
    groupadd ${group}
fi

grep -q "^${user}:" /etc/passwd
if [ "$?" != 0 ]; then
    useradd -r -M -g $group -s $(grep 'nologin' /etc/shells|head -1) $user
fi

##################################################################
#                         LOG DIR                                #
##################################################################

mkdir -p $NGINX_LOG_DIR $LOG_DIR/php-fpm

chown -R ${user}:${group} $LOG_DIR

##################################################################
#                         RUN DIR                                #
##################################################################

mkdir -p $BASE_DIR/run/nginx

#chown -R ${user}:${group} $BASE_DIR/run
##################################################################
#                         DATA DIR                               #
##################################################################

mkdir -p $DATA_DIR/cache/php
mkdir -p $TMP_DATA_DIR/nginx

mkdir -p $DATA_DIR/{sqlite3,preview}

mkdir -p $DATA_DIR/preview/{flash,pdf,office,txt,html}

chown -R ${user}:${group} $DATA_DIR/{sqlite3,preview}

chown -R ${user}:${group} $UPLOAD_TMP_DIR $TMP_DATA_DIR/nginx $DATA_DIR/cache/php

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

##################################################################
#                         openssl init                           #
##################################################################
ca_file="/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem"
if [ -f "$ca_file" ];then
    cp $ca_file $SSL_CONFIG_DIR/certs/ca-bundle.crt
else
    curl https://curl.haxx.se/ca/cacert.pem -o $SSL_CONFIG_DIR/certs/ca-bundle.crt 1>/dev/null 2>&1
    if [ "$?" != "0" ];then
        :
    fi
fi
