#!/bin/bash

init_dir_only=0;
if [ "$1" = "dir" ];then
    init_dir_only=1;
fi
curr_dir=$(cd "$(dirname "$0")"; pwd);

base_define_file=$curr_dir/base_define.sh

if [ ! -f $base_define_file ]; then
    echo "can't find base_define.sh" >&2;
    exit 1;
fi

. $base_define_file

#if [ "$USER" != "root" ]; then
if [ `whoami` != "root" ]; then
    sudo su
    if [ "$?" != 0 ]; then
        echo "No sudo permissions." >&2;
        return;
    fi
fi

chown -R root:root $BASE_DIR

# {{{ function sed_quote2()
function sed_quote2()
{
    local a=$1;
    # 替换转义符
    a=${a//\\/\\\\}
    # 替换分隔符/
    a=${a//\//\\\/}
    echo $a;
}
# }}}
# {{{ function has_systemd 判断系统是否支持systemd服务启动方式 centos7
function has_systemd()
{
    which systemctl 1>/dev/null 2>&1
}
# }}}
# {{{ function system_user_init()
function system_user_init()
{
    local user=$1
    local group=$2
    if [ -z "$user" -o -z "$group" ]; then
        echo "user or group is zero length!" >&2
        return 1;
    fi

    grep -q "^${group}:" /etc/group
    if [ "$?" != "0" ]; then
        groupadd $group
        if [ "$?" != "0" ]; then
            echo "添加组[${group}]失败" >&2;
            return 1;
        fi
    fi

    grep -q "^${user}:" /etc/passwd
    if [ "$?" != 0 ]; then
        useradd -r -M -g $group -s $(grep 'nologin' /etc/shells|head -1) $user
        if [ "$?" != "0" ]; then
            echo "添加用户[${user}]失败" >&2;
            return 1;
        fi
    fi
}
# }}}
# {{{ function mysql_init()
function mysql_init()
{
    if [ ! -d "$MYSQL_BASE" ]; then
        return 1;
    fi
    if [ "$init_dir_only" = "1" ];then
        mysql_dir_init
        return $?;
    fi
    #for i in `ps -ef|grep mysqld|grep -v grep |awk '{ print $2;}'`; do { kill -9 $i; } done
    #sudo rm -rf $MYSQL_RUN_DIR/* $MYSQL_CONFIG_DIR/.mysql_secret $MYSQL_DATA_DIR/*
    echo "Initialize MySQL Data..."
    mysql_user_init
    mysql_dir_init
    mysql_data_init

    if has_systemd ;then
        mysql_systemd_init
    fi
    echo "Initialize MySQL Data finished."
}
# }}}
# {{{ function mysql_user_init()
function mysql_user_init()
{
    system_user_init "$MYSQL_USER" "$MYSQL_GROUP"
    if [ "$?" != "0" ]; then
        return 1;
    fi
    sed -i.bak.$$ "s/^ \{0,\}\(user \{0,\}= \{0,\}\)[^ ]\{0,\} \{0,\}$/\1${MYSQL_USER}/" $mysql_cnf;
    rm -rf ${mysql_cnf}.bak.*
}
# }}}
# {{{ function mysql_data_init()
# #BASE_DIR
# #MYSQL_BASE
# $mysql_cnf
# $MYSQL_CONFIG_DIR
function mysql_data_init()
{
    if [ "$MYSQL_CONFIG_DIR" = "" ] || [ ! -d "$MYSQL_CONFIG_DIR" ]; then
        echo "mysql config dir not exists." >&2;
        return 1;
    fi
    if [ -z "$mysql_cnf" -o ! -f "$mysql_cnf" ]; then
        echo "ERROR: Can't find my.cnf file. file: $mysql_cnf" >&2;
        return 1;
    fi
    # cat /root/.mysql_secret
    local random_password=`$MYSQL_BASE/bin/mysqld --defaults-file=$mysql_cnf --user=$MYSQL_USER --initialize 2>&1 \
        |grep password|awk -F": " '{print $NF;}'`
    # echo $random_password;
    echo $random_password > $MYSQL_CONFIG_DIR/.mysql_secret.rand

    local NEW_PASSWORD="$MYSQL_PASSWORD";
    if [ "$NEW_PASSWORD" = "" ];then
        NEW_PASSWORD="chg365"
    fi

    if [ -f $MYSQL_CONFIG_DIR/.mysql_secret ];then
        NEW_PASSWORD=`head -n1 $MYSQL_CONFIG_DIR/.mysql_secret`;
    else
        echo $NEW_PASSWORD > $MYSQL_CONFIG_DIR/.mysql_secret
    fi

    $MYSQL_BASE/bin/mysqld --daemonize --defaults-file=$mysql_cnf > /dev/null &

    if [ "$?" != "0" ];then
        echo "Start MySQL service failed." >&2;
        return 1;
    fi

    ping_mysql "$random_password"

    if [ "$?" != "0" ];then
        echo "Start MySQL service failed." >&2;
        return 1;
    fi

    $MYSQL_BASE/bin/mysqladmin --defaults-file=$mysql_cnf -u root password "$NEW_PASSWORD" -p"$random_password" 2>/dev/null

    if [ "$?" != "0" ];then
        echo "Failed to modify the root MySQL account password." >&2;
        return 1;
    fi

    # {{{ sql初始化
    local sql_file_array;
    local j=0;
    if [ -f "$curr_dir/sql/${project_abbreviation}.sql" ]; then
        sql_file_array[0]="$curr_dir/sql/${project_abbreviation}.sql";
        j=1;
    fi
    for i in `find $curr_dir/sql/ -type f -name "*.sql"|grep -v "${project_abbreviation}.sql"`;
    do
        sql_file_array[$j]=$i;
        ((j++))
    done

    for((i=0;i<${#sql_file_array[@]};i++))
    do
        $MYSQL_BASE/bin/mysql -uroot -p"$NEW_PASSWORD" -S $MYSQL_RUN_DIR/mysql.sock < ${sql_file_array[$i]} 2>/dev/null

        if [ "$?" != "0" ];then
            echo "Failed to initialize the mysql database. sql file: ${sql_file_array[$i]}" >&2;
            return 1;
        fi
    done;
    # }}}

    $MYSQL_BASE/bin/mysqladmin --defaults-file=$mysql_cnf -u root -p"$NEW_PASSWORD" shutdown 2>/dev/null

    if [ "$?" != "0" ];then
        echo "Shutdown Mysql service Failed." >&2;
        return 1;
    fi

    # 修改php配置文件中的mysql密码
    local PHP_CONF=$BASE_DIR/conf/config.php
    if [ ! -f "$PHP_CONF" ];then
        echo "Can't find file: $PHP_CONF . Please manually modify the mysql root password. " >&2;
        return 1;
    fi
    local mysql_user=`$PHP_BASE/bin/php -r "require('$PHP_CONF'); echo MYSQL_USER;"`;
    if [ "$mysql_user" = "root" ];then
        sed -i.bak.$$ "s/define('MYSQL_PASS', '[^'\"]\{1,\}')/define('MYSQL_PASS', '$NEW_PASSWORD')/" $PHP_CONF
        rm -rf ${PHP_CONF}.bak.*
    fi
}
# }}}
# {{{ function mysql_dir_init()
function mysql_dir_init()
{
    mkdir -p $MYSQL_RUN_DIR $MYSQL_DATA_DIR
    #chown -R root:root $MYSQL_BASE
    chown -R $MYSQL_USER:$MYSQL_GROUP $MYSQL_DATA_DIR
    #chown -R $MYSQL_USER:$MYSQL_GROUP $MYSQL_RUN_DIR
}
# }}}
# {{{ function mysql_systemd_init()
function mysql_systemd_init()
{
    if [ ! -f "$MYSQL_BASE/usr/lib/systemd/system/mysqld.service" ]; then
        echo "mysqld.service file not exists." >&2
        return 1;
    fi
    local service_file="/usr/lib/systemd/system/${project_abbreviation}.mysqld.service"
    cp $MYSQL_BASE/usr/lib/systemd/system/mysqld.service $service_file

    local pid_file=`sed -n 's/^ \{0,\}pid-file \{1,\}= \{0,\}\(.\{1,\}\) \{0,\}$/\1/p' $mysql_cnf

    sed -i.bak.$$ "s/^User=.\{1,\}$/User=$MYSQL_USER/" $service_file
    sed -i.bak.$$ "s/^Group=.\{1,\}$/Group=$MYSQL_GROUP/" $service_file
    sed -i.bak.$$ "s/^PIDFile=.\{1,\}$/PIDFile=$pid_file/" $service_file
    sed -i.bak.$$ 's/^\(ExecStartPre=\)/# \1/' $service_file
    sed -i.bak.$$ "s/^ExecStart=.\{1,\}$/ExecStart=$( sed_quote2 $MYSQL_BASE/bin/mysqld ) --daemonize --defaults-file=$(sed_quote2 ${mysql_cnf})/" $service_file
    sed -i.bak.$$ 's/^\(After=syslog.target\)/# \1/' $service_file
    sed -i.bak.$$ 's/^EnvironmentFile=/# EnvironmentFile=/' $service_file

    # 
    systemctl enable `basename $service_file`
    systemctl daemon-reload
}
# }}}
# {{{ function ping_mysql()
function ping_mysql()
{
    local mysql_password=$1
    local ping_res="1";
    local mysql_sleep=0;
    local cmd_mysql_ping="$MYSQL_BASE/bin/mysqladmin --defaults-file=$mysql_cnf -u root -p\"$mysql_password\" ping > /dev/null 2>&1"

    #Ping mysql
    while test 0 != "$ping_res";
    do
        sleep 1

        mysql_sleep=$((mysql_sleep + 1))

        if test $mysql_sleep -gt 30;then
            return 1;
        fi

        if [ ! -S "$MYSQL_RUN_DIR/mysql.sock" ];then
            continue
        fi

        eval $cmd_mysql_ping

        ping_res=$?
    done

    sleep 1
}
# }}}
# {{{ function openssl_init()
function openssl_init()
{
    if [ "$init_dir_only" = "1" ];then
        return;
    fi
    local ca_file="/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem"
    if [ -f "$ca_file" ];then
        cp $ca_file $SSL_CONFIG_DIR/certs/ca-bundle.crt
    else
        curl https://curl.haxx.se/ca/cacert.pem -o $SSL_CONFIG_DIR/certs/ca-bundle.crt 1>/dev/null 2>&1
        if [ "$?" != "0" ];then
            return 1;
        fi
    fi
}
# }}}
# {{{ function php_fpm_init()
function php_fpm_init()
{
    if [ ! -d "$PHP_BASE" ]; then
        return 1;
    fi
    if [ "$init_dir_only" = "1" ];then
        php_fpm_dir_init
        return $?;
    fi
    echo "Initialize php-fpm..."
    php_fpm_user_init
    php_fpm_dir_init
    #php_fpm_data_init

    if has_systemd ;then
        php_fpm_systemd_init
    fi
    echo "Initialize php-fpm finished."
}
# }}}
# {{{ function php_fpm_user_init()
function php_fpm_user_init()
{
    system_user_init "$PHP_FPM_USER" "$PHP_FPM_GROUP"
    if [ "$?" != "0" ]; then
        return 1;
    fi

    # user
    sed -i.bak.$$ "s/^ \{0,\}user \{0,\}= \{0,\}.\{0,\}$/user = $PHP_FPM_USER/" $PHP_FPM_CONFIG_DIR/php-fpm.d/www.conf;

    # group
    sed -i.bak.$$ "s/^ \{0,\}group \{0,\}= \{0,\}.\{0,\}$/group = $PHP_FPM_GROUP/" $PHP_FPM_CONFIG_DIR/php-fpm.d/www.conf;

    rm -rf ${PHP_FPM_CONFIG_DIR}/php-fpm.d/www.conf.bak.*
}
# }}}
# {{{ function php_fpm_dir_init()
function php_fpm_dir_init()
{
    mkdir -p ${LOG_DIR}/php-fpm ${BASE_DIR}/run
    chown -R ${PHP_FPM_USER}:${PHP_FPM_GROUP} $LOG_DIR/php-fpm
}
# }}}
# {{{ function php_fpm_systemd_init()
function php_fpm_systemd_init()
{
    if [ ! -f "$curr_dir/service/php-fpm.service" ]; then
        echo "php-fpm.service file not exists." >&2
        return 1;
    fi

    local service_file="/usr/lib/systemd/system/${project_abbreviation}.php-fpm.service"
    cp $curr_dir/service/php-fpm.service $service_file

    local pid_file=`sed -n 's/^ \{0,\}pid \{0,\}= \{0,\}\(.\{1,\}\)$/\1/p' $PHP_FPM_CONFIG_DIR/php-fpm.conf`

    # Before=nginx.service

    sed -i.bak.$$ "s/^PIDFile=/PIDFile=$(sed_quote2 $pid_file )/" $service_file
    #sed -i.bak.$$ "s/^Type=/Type=forking/" $service_file

    systemctl enable `basename $service_file`
    systemctl daemon-reload
}
# }}}
# {{{ function nginx_init()
function nginx_init()
{
    if [ ! -d "$NGINX_BASE" ]; then
        return 1;
    fi
    if [ "$init_dir_only" = "1" ];then
        nginx_dir_init
        return $?;
    fi
    echo "Initialize nginx ..."
    nginx_user_init
    nginx_dir_init
    #nginx_data_init

    if has_systemd ;then
        nginx_systemd_init
    fi
    echo "Initialize nginx finished."
}
# }}}
# {{{ function nginx_user_init()
function nginx_user_init()
{
    system_user_init "$NGINX_USER" "$NGINX_GROUP"
    if [ "$?" != "0" ]; then
        return 1;
    fi

    # user
    sed -i.bak.$$ "s/^ \{0,\}user \{0,\}\{0,\}.\{0,\}$/user  $NGINX_USER $NGINX_GROUP;/" $NGINX_CONFIG_DIR/conf/nginx.conf;

    rm -rf $NGINX_CONFIG_DIR/conf/nginx.conf.bak.$$
}
# }}}
# {{{ function nginx_dir_init()
function nginx_dir_init()
{
    mkdir -p $NGINX_LOG_DIR $NGINX_RUN_DIR $TMP_DATA_DIR/nginx $TMP_DATA_DIR/dehydrated
    chown -R ${NGINX_USER}:${NGINX_GROUP} $NGINX_LOG_DIR $TMP_DATA_DIR/nginx
}
# }}}
# {{{ function nginx_systemd_init()
function nginx_systemd_init()
{
    if [ ! -f "$curr_dir/service/nginx.service" ]; then
        echo "nginx.service file not exists." >&2
        return 1;
    fi

    local service_file="/usr/lib/systemd/system/${project_abbreviation}.nginx.service"
    cp $curr_dir/service/nginx.service $service_file

    local pid_file=`sed -n 's/^ \{0,\}pid \{0,\}\(.\{1,\}\) \{0,\}; \{0,\}$/\1/p' $NGINX_CONFIG_DIR/conf/nginx.conf`

    sed -i.bak.$$ "s/^PIDFile=/PIDFile=$(sed_quote2 $pid_file )/" $service_file
    #sed -i.bak.$$ "s/^Type=/Type=forking/" $service_file

    systemctl enable `basename $service_file`
    systemctl daemon-reload

    for i in `sed -n 's/^ \{0,\}listen \{1,\}\([0-9]\{1,\}\).\{0,\};$/\1/p' $NGINX_CONFIG_DIR/conf/nginx.conf`;
    do
        firewall-cmd --zone=public --add-port=${i}/tcp --permanent
    done

    #firewall-cmd --permanent --add-service=http
    #firewall-cmd --permanent --add-service=https

    firewall-cmd --reload
}
# }}}
# {{{ function dehydrated_init()
function dehydrated_init()
{
    if [ "$init_dir_only" = "1" ];then
        return;
    fi
    if has_systemd ;then
    if [ ! -d "$DEHYDRATED_CONFIG_DIR" ];then
        echo "domains.txt目录不存在" >&2
        return 1;
    fi

    domain_init

    if [ "$?" != "0" ];then
        return 1;
    fi

    grep -q '.\{1,\}\..\{1,\}' $DEHYDRATED_CONFIG_DIR/domains.txt
    if [ "$?" != "0" ];then
        echo "not find domain name" >&2
        return;
    fi
    create_certificates
    if [ "$?" != "0" ];then
        return 1;
    fi
    renew_cret_crontab_init
}
# }}}
# {{{ function create_certificates()
function create_certificates()
{
    #启动nginx服务
    $NGINX_BASE/sbin/nginx

    if [ "$?" != "0" ];then
        echo "start nginx service faild." >&2
        return 1;
    fi

    echo "Start create certificates ...."

    $BASE_DIR/sbin/renew_cert.sh
    if [ ! -d "$DEHYDRATED_CONFIG_DIR/certs" ];then
        echo "Create certificates faild." >&2
        $NGINX_BASE/sbin/nginx -s stop
        return 1;
    fi

    $NGINX_BASE/sbin/nginx -s stop
    local domain=""
    #domain=`cat $DEHYDRATED_CONFIG_DIR/domains.txt|head -1|tr ' ' '\n'|rev |sort |head -1|rev`
    local domains1=`cat $DEHYDRATED_CONFIG_DIR/domains.txt|head -1|tr ' ' '\n'`
    local domains2=`find $DEHYDRATED_CONFIG_DIR/certs/ -maxdepth 1 -mindepth 1 -type d|xargs -i basename {}|grep -v '^example.com$'`;
    for k in `cat $DEHYDRATED_CONFIG_DIR/domains.txt`;
    do
        domains1=`echo $k|tr ' ' '\n'`;
        for i in `echo "$domains1"`;
        do
            for j in `echo "$domains2"`;
            do
                if [ "$i" = "$j" ];then
                    domain=$i;
                    break 2;
                fi
            done
        done
    done

    if [ "$domain" = "" ];then
        echo "get domain name faild." >&2
        return 1;
    fi

    # 更改nginx使用的证书
    sed -i.bak.$$ "s/example.com/$domain/" $NGINX_CONFIG_DIR/conf/nginx.conf
    rm -rf $NGINX_CONFIG_DIR/conf/nginx.conf.bak.*
}
# }}}
# {{{ function domain_init()
function domain_init()
{
    if [ ! -f "$DEHYDRATED_CONFIG_DIR/domains.txt" ]; then
        # echo `date +%Y%m%d-%H%M%S`
        touch $DEHYDRATED_CONFIG_DIR/domains.txt
    else
        # [a-z0-9A-Z-.] 中文 .
        grep -q '.\{1,\}\..\{1,\}' $DEHYDRATED_CONFIG_DIR/domains.txt
        if [ "$?" = "0" ];then
            return;
        fi
    fi

    while read -t30 -p 'Please input domains: [Ctrl + D] or [quit] is finished\x0a    Example: example.com www.example.com' line;
    do
        if [ "$line" == "quit" -o "$line" = "exit" ]; then
            break;
        fi
        echo $line >> $DEHYDRATED_CONFIG_DIR/domains.txt
    done
}
# }}}
# {{{ function renew_cret_crontab_init()
function renew_cret_crontab_init()
{
    if has_systemd ;then
        if ! systemctl -a|grep -q crond.service ;then
            systemctl enable crond
        fi
        if ! systemctl status crond.service; then
            systemctl start crond
        fi
    fi

    local PROGRAM=$BASE_DIR/sbin/renew_cert.sh
    if crontab -l 2>/dev/null | grep -qF $PROGRAM ;then
        return;
    fi

    local day=`date +%e`;
    day=${day## }
    if [ "$day" -gt 28];then
        day=28
    fi

    local CRONTAB_CMD="#每周日凌晨4:15 更新ssl证书\
15 4 $day * * $PROGRAM > $BASE_DIR/log/dehydrated.log 2>&1 &"

    echo "$CRONTAB_CMD") | crontab -

    if crontab -l 2>/dev/null | grep -qF $PROGRAM ;then
        return;
    else
        echo "fail to add crontab $PROGRAM" >&2
        return 1
    fi
}
# }}}

##################################################################
#                         DATA DIR                               #
##################################################################

##################################################################
#                         php cache file                         #
##################################################################

#$BASE_DIR/bin/init_php_cache.php

##################################################################
#                         mysql init                             #
##################################################################

mysql_init

##################################################################
#                         openssl init                           #
##################################################################

openssl_init

##################################################################
#                         php-fpm init                           #
##################################################################

php_fpm_init

##################################################################
#                         nginx init                             #
##################################################################
nginx_init
#systemctl -a|grep nss
#systemctl status nginx
#systemctl start nginx
#systemctl stop nginx
#systemctl reload nginx

##################################################################
#                         dehydrated init                             #
##################################################################
dehydrated_init

