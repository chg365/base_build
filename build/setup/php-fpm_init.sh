#!/bin/bash

curr_dir=$(cd "$(dirname "$0")"; pwd);

base_define_file=$curr_dir/base_define.sh

if [ ! -f $base_define_file ]; then
    echo "can't find base_define.sh";
    exit;
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

# {{{ function php_fpm_user_init()
function php_fpm_user_init()
{
    grep -q "^${PHP_FPM_GROUP}:" /etc/group
    if [ "$?" != 0 ]; then
        groupadd $PHP_FPM_GROUP
    fi

    grep -q "^${PHP_FPM_USER}:" /etc/passwd
    if [ "$?" != 0 ]; then
        useradd -r -M -g $PHP_FPM_GROUP -s $(grep 'nologin' /etc/shells|head -1) $PHP_FPM_USER
    fi
}
# }}}

mkdir -p $BASE_DIR/run
mkdir -p $LOG_DIR/php-fpm

php_fpm_user_init
chown -R $PHP_FPM_USER:$PHP_FPM_GROUP $LOG_DIR/php-fpm
