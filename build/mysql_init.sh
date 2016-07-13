#!/bin/bash

NEW_PASSWORD="chg365" #mysql root密码

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

# {{{ function mysql_user_init()
function mysql_user_init()
{
    grep -q "^mysql" /etc/group
    if [ "$?" != 0 ]; then
        groupadd mysql
    fi

    grep -q "^mysql" /etc/passwd
    if [ "$?" != 0 ]; then
        useradd -r -M -g mysql -s $(grep 'nologin' /etc/shells) mysql
    fi
}
# }}}
# {{{ function mysql_init()
# #BASE_DIR
# #MYSQL_BASE
# $mysql_cnf
# $NEW_PASSWORD
# $MYSQL_CONFIG_DIR
function mysql_init()
{
    if [ "$MYSQL_CONFIG_DIR" = "" ] || [ ! -d $MYSQL_CONFIG_DIR ]; then
        echo "mysql config dir not exists.";
        return 1;
    fi
    if [ ! -f $mysql_cnf ]; then
        echo "ERROR: Can't find my.cnf file. file: $mysql_cnf";
        return 1;
    fi
    # cat /root/.mysql_secret
    random_password=`$MYSQL_BASE/bin/mysqld --defaults-file=$mysql_cnf --user=mysql --initialize 2>&1|grep password|awk -F": " '{print $NF;}'`
    # echo $random_password;

    if [ "$NEW_PASSWORD" = "" ];then
        NEW_PASSWORD="chg365"
    fi

    if [ -f $MYSQL_CONFIG_DIR/.mysql_secret ];then
        NEW_PASSWORD=`head -n1 $MYSQL_CONFIG_DIR/.mysql_secret`;
    else
        echo $NEW_PASSWORD > $MYSQL_CONFIG_DIR/.mysql_secret
    fi

    $MYSQL_BASE/bin/mysqld_safe --defaults-file=$mysql_cnf > /dev/null &

    if [ "$?" != "0" ];then
        echo "Start MySQL service failed."
        return 1;
    fi

    ping_mysql "$random_password"

    if [ "$?" != "0" ];then
        echo "Start MySQL service failed."
        return 1;
    fi

    $MYSQL_BASE/bin/mysqladmin --defaults-file=$mysql_cnf -u root password "$NEW_PASSWORD" -p"$random_password" 2>/dev/null

    if [ "$?" != "0" ];then
        echo "Failed to modify the root MySQL account password."
        return 1;
    fi

    $MYSQL_BASE/bin/mysql -uroot -p"$NEW_PASSWORD" -S $MYSQL_RUN_DIR/mysql.sock < $curr_dir/chg_base.sql 2>/dev/null

    if [ "$?" != "0" ];then
        echo "Failed to initialize the mysql database."
        return 1;
    fi

    $MYSQL_BASE/bin/mysqladmin --defaults-file=$mysql_cnf -u root -p"$NEW_PASSWORD" shutdown 2>/dev/null

    if [ "$?" != "0" ];then
        echo "Shutdown Mysql service Failed."
        return 1;
    fi

    # 修改php配置文件中的mysql密码
    PHP_CONF=$BASE_DIR/conf/config.php
    if [ ! -f $PHP_CONF ];then
        echo "Can't find file: $PHP_CONF . Please manually modify the mysql root password. "
        return 1;
    fi
    mysql_user=`$PHP_BASE/bin/php -r "require('$PHP_CONF'); echo MYSQL_USER;"`;
    if [ "$mysql_user" = "root" ];then
        sed -i "s/define('MYSQL_PASS', '[^'\"]\{1,\}')/define('MYSQL_PASS', '$NEW_PASSWORD')/" $PHP_CONF
    fi
}
# }}}
# {{{ function ping_mysql()
function ping_mysql()
{
    local MYSQL_PASSWORD=$1
    local PING_RES="1";
    local MYSQL_SLEEP=0;
    local CMD_MYSQL_PING="$MYSQL_BASE/bin/mysqladmin --defaults-file=$mysql_cnf -u root -p\"$MYSQL_PASSWORD\" ping > /dev/null 2>&1"

    #Ping mysql
    while test 0 != "$PING_RES";do
        sleep 1

        MYSQL_SLEEP=$((MYSQL_SLEEP + 1))

        if test $MYSQL_SLEEP -gt 30;then
            return 1;
        fi

        if [ ! -S "$MYSQL_RUN_DIR/mysql.sock" ];then
            continue
        fi

        eval $CMD_MYSQL_PING

        PING_RES=$?
    done

    sleep 1

}
# }}}

#for i in `ps -ef|grep mysqld|grep -v grep |awk '{ print $2;}'`; do { kill -9 $i; } done
#sudo rm -rf $MYSQL_RUN_DIR/* $MYSQL_CONFIG_DIR/.mysql_secret $MYSQL_DATA_DIR/*

mysql_user_init
mkdir -p $MYSQL_RUN_DIR $MYSQL_DATA_DIR
chown -R root:root $MYSQL_BASE
chown -R mysql:mysql $MYSQL_DATA_DIR $MYSQL_RUN_DIR
mysql_init
