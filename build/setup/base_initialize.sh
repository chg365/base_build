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

#if [ "$USER" != "root" ]; then
if [ `whoami` != "root" ]; then
    echo "请使用root用户执行此脚本." >&2
    exit 1;
fi

. $base_define_file

# {{{ function has_chown_finished 已经修改过目录权限
function has_chown_finished()
{
    if [ "$POSTGRESQL_USER" != "" ]; then
        local num=`ls -l $POSTGRESQL_DATA_DIR/../ |grep $POSTGRESQL_USER|wc -l`;
        if [ "$num" != "" -a "$num" -gt "0" ]; then
            return 0;
        fi
    fi
    if [ "$MYSQL_USER" != "" ]; then
        local num=`ls -l $MYSQL_DATA_DIR/../ |grep $MYSQL_USER|wc -l`;
        if [ "$num" != "" -a "$num" -gt "0" ]; then
            return 0;
        fi
    fi
    return 1;
}
# }}}
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
    #for i in `ps -ef|grep mysqld|grep -v grep |awk '{ print $2;}'`; do { kill -9 $i; } done
    #sudo rm -rf $MYSQL_RUN_DIR/* $MYSQL_CONFIG_DIR/.mysql_secret $MYSQL_DATA_DIR/*
    echo "Initialize MySQL ..."
    mysql_user_init
    if [ "$?" != "0" ]; then
        return 1;
    fi
    mysql_dir_init
    if [ "$?" != "0" ]; then
        return 1;
    fi
    if [ "$init_dir_only" = "1" ];then
        echo "Initialize MySQL finished."
        return 0;
    fi

    echo "Initialize MySQL Data..."
    mysql_data_init
    if [ "$?" != "0" ]; then
        return 1;
    fi
    echo "Initialize MySQL Data finished."

    if has_systemd ;then
        mysql_systemd_init
        if [ "$?" != "0" ]; then
            return 1;
        fi
    fi
    echo "Initialize MySQL finished."
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
# {{{ function mysql_dir_init()
function mysql_dir_init()
{
    mkdir -p $MYSQL_RUN_DIR $MYSQL_DATA_DIR ${LOG_DIR}/mysql
    #chown -R root:root $MYSQL_BASE
    chown -R $MYSQL_USER:$MYSQL_GROUP $MYSQL_DATA_DIR ${LOG_DIR}/mysql $MYSQL_RUN_DIR
    #chown -R $MYSQL_USER:$MYSQL_GROUP $MYSQL_RUN_DIR
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
    local random_password=""
    local log_file=`get_mysql_log_file_name`
    if [ -z "$log_file" ];then
        return 1;
    fi
    if [ -f "$log_file" ];then
        random_password=`get_mysql_temp_password`
        if [ "$?" != "0" ];then
            echo "获得随机密码失败" >&2
            return 1;
        fi
    fi
    if [ -z "$random_password" ];then
        # cat /root/.mysql_secret
        $MYSQL_BASE/bin/mysqld --defaults-file=$mysql_cnf --initialize
        if [ "$?" != "0" ];then
            echo "mysql初始化失败" >&2
            return 1;
        fi
        random_password=`get_mysql_temp_password`
        if [ "$?" != "0" ];then
            echo "获得随机密码失败" >&2
            return 1;
        fi
    fi

    # echo $random_password;

    if [ -z "$random_password" ];then
        echo "初始化mysql密码失败" >&2
        return 1;
    fi

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

    # mysql是否已经启动
    local pid_file=`get_mysql_pid_file_name`;
    if [ -z "$pid_file" ];then
        return 1;
    fi
    local is_run="1" # 0是已经启动
    if [ -f "$pid_file" ];then
        local pid=`cat $pid_file|head -1`;
        if [ -n "$pid" ];then
            # S 状态码 D 不可中断 R 运行 S 中断 T 停止 Z 僵死
            # D    uninterruptible sleep (usually IO)  不间断睡眠（通常为IO）
            # R    running or runnable (on run queue)  运行或可运行（运行队列）
            # S    interruptible sleep (waiting for an event to complete) 可中断睡眠（等待事件完成）
            # T    stopped by job control signal  由作业控制信号停止
            # t    stopped by debugger during the tracing 在跟踪期间由调试器停止
            # W    paging (not valid since the 2.6.xx kernel)
            # X    dead (should never be seen) 死了（不应该看到）
            # Z    defunct ("zombie") process, terminated but not reaped by its parent 停止（“僵尸”）进程，终止，但没有被父母收获
            ps -lf -p $pid 1>/dev/null
            is_run=$?
        fi
    fi

    if [ "$is_run" != "0" ];then
        $MYSQL_BASE/bin/mysqld --defaults-file=$mysql_cnf --daemonize > /dev/null &
    fi

    if [ "$?" != "0" ];then
        echo "Start MySQL service failed." >&2;
        return 1;
    fi

    # 这里如果只要服务启动了，密码错误也不会报错
    ping_mysql "$random_password"
    if [ "$?" != "0" ];then
        echo "Start MySQL service failed." >&2;
        return 1;
    fi

    $MYSQL_BASE/bin/mysql --defaults-file=$mysql_cnf -u root -p${random_password} --connect-expired-password -e quit >/dev/null 2>&1
    if [ "$?" != "0" ];then
        $MYSQL_BASE/bin/mysql --defaults-file=$mysql_cnf -u root -p${NEW_PASSWORD} -e quit >/dev/null 2>&1
        if [ "$?" != "0" ];then
            echo "mysql 测试随机密码和新密码都失败" >&2
            return 1;
        fi
        random_password=${NEW_PASSWORD}
    fi

    if [ "$random_password" != "$NEW_PASSWORD" ];then
        $MYSQL_BASE/bin/mysqladmin --defaults-file=$mysql_cnf -u root password "$NEW_PASSWORD" -p"$random_password" 2>/dev/null
        if [ "$?" != "0" ];then
            echo "Failed to modify the root MySQL account password." >&2;
            return 1;
        fi
    fi

    sql_init $NEW_PASSWORD

    $MYSQL_BASE/bin/mysqladmin --defaults-file=$mysql_cnf -u root -p"$NEW_PASSWORD" shutdown 2>/dev/null

    if [ "$?" != "0" ];then
        echo "Shutdown Mysql service Failed." >&2;
        return 1;
    fi

    # 修改php配置文件中的mysql密码
    mod_php_config_mysql_password $NEW_PASSWORD

    return 0;
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

    local pid_file=`get_mysql_pid_file_name`
    if [ -z "$pid_file" ];then
        return 1;
    fi

    sed -i.bak.$$ "s/^User=.\{1,\}$/User=$MYSQL_USER/" $service_file
    sed -i.bak.$$ "s/^Group=.\{1,\}$/Group=$MYSQL_GROUP/" $service_file
    sed -i.bak.$$ "s/^PIDFile=.\{1,\}$/PIDFile=$( sed_quote2 $pid_file)/" $service_file
    sed -i.bak.$$ 's/^\(ExecStartPre=\)/# \1/' $service_file
    sed -i.bak.$$ "s/^ExecStart=.\{1,\}$/ExecStart=$( sed_quote2 $MYSQL_BASE/bin/mysqld ) --defaults-file=$(sed_quote2 ${mysql_cnf}) --daemonize/" $service_file
    sed -i.bak.$$ 's/^\(After=syslog.target\)/# \1/' $service_file
    sed -i.bak.$$ 's/^EnvironmentFile=/# EnvironmentFile=/' $service_file

    rm -rf ${service_file}.bak.*

    #
    systemctl enable `basename $service_file` > /dev/null && \
    systemctl daemon-reload > /dev/null
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
}
# }}}
# {{{ function get_mysql_pid_file_name()
function get_mysql_pid_file_name()
{
    local pid_file=`sed -n 's/^ \{0,\}pid-file \{0,\}= \{0,\}\(.\{1,\}\) \{0,\}$/\1/p' $mysql_cnf`

    if [ -z "$pid_file" ];then
        echo "my.cnf文件中没有设置pid-file参数" >&2
        return 1;
    fi

    echo "$pid_file"
    return;
}
# }}}
# {{{ function get_mysql_log_file_name()
function get_mysql_log_file_name()
{
    local log_file=`sed -n 's/^ \{0,\}log_error \{0,\}= \{0,\}\(.\{1,\}\) \{0,\}$/\1/p' $mysql_cnf`

    if [ -z "$log_file" ];then
        echo "my.cnf文件中没有设置log_error参数" >&2
        return 1;
    fi

    echo "$log_file"
    return;
}
# }}}
# {{{ function get_mysql_temp_password()
function get_mysql_temp_password()
{
    local log_file=`get_mysql_log_file_name`
    if [ ! -f "$log_file" ];then
        echo "文件不存在 file: $log_file" >&2
        return 1;
    fi

    local password=`grep 'A temporary password is generated' $log_file|awk -F": " '{print $NF;}'`
    if [ -z "$password" ];then
        echo "获得mysql初始化密码失败" >&2
        return 1;
    fi
    echo $password;
}
# }}}

# {{{ function postgresql_init()
function postgresql_init()
{
    if [ ! -d "$POSTGRESQL_BASE" ]; then
        return 1;
    fi
    echo "Initialize PostgreSQL ..."
    postgresql_user_init
    if [ "$?" != "0" ]; then
        return 1;
    fi
    postgresql_dir_init
    if [ "$?" != "0" ]; then
        return 1;
    fi
    if [ "$init_dir_only" = "1" ];then
        echo "Initialize PostgreSQL finished."
        return $?;
    fi
    postgresql_data_init
    if [ "$?" != "0" ]; then
        return 1;
    fi

    if has_systemd ;then
        postgresql_systemd_init
        if [ "$?" != "0" ]; then
            return 1;
        fi
    fi
    echo "Initialize PostgreSQL finished."
}
# }}}
# {{{ function postgresql_user_init()
function postgresql_user_init()
{
    system_user_init "$POSTGRESQL_USER" "$POSTGRESQL_GROUP"
    if [ "$?" != "0" ]; then
        return 1;
    fi
}
# }}}
# {{{ function postgresql_data_init()
# #BASE_DIR
# #MYSQL_BASE
# $mysql_cnf
# $MYSQL_CONFIG_DIR
function postgresql_data_init()
{
    sudo -u $POSTGRESQL_USER $POSTGRESQL_BASE/bin/pg_ctl -D $POSTGRESQL_DATA_DIR initdb
    # 启动服务
    # sudo -u $POSTGRESQL_USER $POSTGRESQL_BASE/bin/pg_ctl -D $POSTGRESQL_DATA_DIR -l $LOG_DIR/pgsql/pgsql.log start
    # 创建数据库
    #sudo -u $POSTGRESQL_USER $POSTGRESQL_BASE/bin/createdb test
    #sudo -u $POSTGRESQL_USER $POSTGRESQL_BASE/bin/psql test
#        initdb: 无法为本地化语言环境"zh_CN.utf-8"找到合适的文本搜索配置
#        缺省的文本搜索配置将会被设置到"simple"
#
#        禁止为数据页生成校验和.
#
#        警告:为本地连接启动了 "trust" 认证.
#        你可以通过编辑 pg_hba.conf 更改或你下次
#        行 initdb 时使用 -A或者--auth-local和--auth-host选项.
#
#        Success. You can now start the database server using:
#

}
# }}}
# {{{ function postgresql_dir_init()
function postgresql_dir_init()
{
    mkdir -p $POSTGRESQL_RUN_DIR $POSTGRESQL_DATA_DIR ${LOG_DIR}/pgsql
    chown -R $POSTGRESQL_USER:$POSTGRESQL_GROUP $POSTGRESQL_DATA_DIR ${LOG_DIR}/pgsql
}
# }}}
# {{{ function postgresql_systemd_init()
function postgresql_systemd_init()
{
    local src_file="$curr_dir/service/postgresql.service"
    if [ ! -f "$src_file" ]; then
        echo "postgresql.service file not exists." >&2
        return 1;
    fi

    local service_file="/usr/lib/systemd/system/${project_abbreviation}.postgresql.service"
    cp $src_file $service_file

    sed -i.bak.$$ "s/POSTGRESQL_BASE/$(sed_quote2 $POSTGRESQL_BASE)/g" $service_file
    sed -i.bak.$$ "s/POSTGRESQL_DATA_DIR/$(sed_quote2 $POSTGRESQL_DATA_DIR)/g" $service_file

    rm -rf ${service_file}.bak.*

    systemctl enable `basename $service_file`
    systemctl daemon-reload

    firewall-cmd --state 1>/dev/null 2>&1
    local firewall_status=$?


    # 只是本机用，默认就不开防火墙了
    POSTGRESQL_PORT="5432"
    if [ "$firewall_status" = "0" ];then
        :
        #firewall-cmd --permanent --zone=public --add-port=${POSTGRESQL_PORT}/tcp
        #firewall-cmd --permanent --zone=public --add-service=postgresql

        #firewall-cmd --reload
    fi
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
    fi
    if [ "$?" != "0" ];then
        echo "init openssl ca-bundle.crt file faild." >&2
        return 1;
    fi
}
# }}}

# {{{ function php_fpm_init()
function php_fpm_init()
{
    if [ ! -d "$PHP_BASE" ]; then
        return 1;
    fi
    echo "Initialize php-fpm..."
    php_fpm_user_init
    php_fpm_dir_init
    if [ "$init_dir_only" = "1" ];then
        echo "Initialize php-fpm dir finished."
        return $?;
    fi
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
    #if [ -f "$service_file" ];then
    #    echo "${service_file##*/} file is exists." >&2
    #    return;
    #fi

    cp $curr_dir/service/php-fpm.service $service_file

    local pid_file=`sed -n 's/^ \{0,\}pid \{0,\}= \{0,\}\(.\{1,\}\)$/\1/p' $PHP_FPM_CONFIG_DIR/php-fpm.conf`

    # Before=nginx.service

    sed -i.bak.$$ "s/^PIDFile=.\{0,\}$/PIDFile=$(sed_quote2 $pid_file )/" $service_file
    #sed -i.bak.$$ "s/^Type=/Type=forking/" $service_file
    rm -rf ${service_file}.bak.*

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
    echo "Initialize nginx ..."
    nginx_user_init
    nginx_dir_init
    local res=$?
    if [ "$init_dir_only" = "1" ];then
        echo "Initialize nginx dir finished."
        return $res;
    fi

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
    sed -i.bak.$$ "s/^ \{0,\}user \{0,\}.\{0,\}$/user  $NGINX_USER $NGINX_GROUP;/" $NGINX_CONFIG_DIR/conf/nginx.conf;

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

    sed -i.bak.$$ "s/^PIDFile=.\{0,\}$/PIDFile=$(sed_quote2 $pid_file )/" $service_file
    sed -i.bak.$$ "s/NGINX_RUN_DIR/$(sed_quote2 $NGINX_RUN_DIR)/g" $service_file
    sed -i.bak.$$ "s/NGINX_BASE/$(sed_quote2 $NGINX_BASE)/g" $service_file
    #sed -i.bak.$$ 's/^\(After=.\{0,\}\)nss-lookup.target\(.\{0,\}\)$/\1\2/' $service_file
    #sed -i.bak.$$ "s/^Type=/Type=forking/" $service_file

    rm -rf ${service_file}.bak.*

    systemctl enable `basename $service_file`
    systemctl daemon-reload

    firewall-cmd --state 1>/dev/null 2>&1
    local firewall_status=$?

    for i in `sed -n 's/^ \{0,\}listen \{1,\}\([0-9]\{1,\}\).\{0,\};$/\1/p' $NGINX_CONFIG_DIR/conf/nginx.conf`;
    do
        if [ "$firewall_status" = "0" ];then
            firewall-cmd --permanent --zone=public --add-port=${i}/tcp > /dev/null
        fi
    done

    if [ "$firewall_status" = "0" ];then
        #firewall-cmd --permanent --add-service=http
        #firewall-cmd --permanent --add-service=https

        firewall-cmd --reload > /dev/null
    fi
}
# }}}

# {{{ function dehydrated_init()
function dehydrated_init()
{
    if [ "$init_dir_only" = "1" ];then
        return;
    fi
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
        return 1;
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

    echo "Create certificates start ...."

    $BASE_DIR/sbin/renew_cert.sh
    if [ "$?" != "0" -o ! -d "$DEHYDRATED_CONFIG_DIR/certs" ];then
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
                    break 3;
                fi
            done
        done
    done

    if [ "$domain" = "" ];then
        echo "get domain name faild." >&2
        return 1;
    fi

    #成功后，强制使用https,把http跳转https的配置的注释去掉
    local line1=`sed -n '/http_301\.conf/=' $NGINX_CONFIG_DIR/conf/nginx.conf|head -1`
    local line2="0"
    local d=10000
    local a=""
    for i in `sed -n '/default_locations\.conf/=' $NGINX_CONFIG_DIR/conf/nginx.conf`;
    do
        a=$((${i}-${line1}))
        a=${a/-/};
        if [ "$a" -lt "$d" ];then
            d=$a;
            line2=$i;
        fi
    done

    sed -i.bak.$$ "${line1}s/^\([\t ]\{0,\}\)#\{1,\}/\1/" $NGINX_CONFIG_DIR/conf/nginx.conf
    sed -i.bak.$$ "${line2}s/^\([\t ]\{0,\}\)include/\1#include/" $NGINX_CONFIG_DIR/conf/nginx.conf

    # 更改nginx使用的证书
    sed -i.bak.$$ "s/example.com/$domain/" $NGINX_CONFIG_DIR/conf/nginx.conf
    # 更新nginx服务器的服务器名
    sed -i.bak.$$ "s/SERVER_NAME/$(grep "\<${domain}\>" $DEHYDRATED_CONFIG_DIR/domains.txt)/" $NGINX_CONFIG_DIR/conf/nginx.conf
    rm -rf $NGINX_CONFIG_DIR/conf/nginx.conf.bak.*
    echo "Create certificates finished ...."
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

    local line=""
    echo "Please input domains: [Ctrl + D] or [quit] is finished"
    echo "    Example: example.com www.example.com"
    while read -t30 -p '' line;
    do
        line=`echo "$line"|sed -n 's/^ \{0,\}\(.\{1,\}\) \{0,\}$/\1/p'`
        if [ "$line" == "quit" -o "$line" = "exit" ]; then
            break;
        fi
        if [ "$line" != "" ]; then
            echo $line >> $DEHYDRATED_CONFIG_DIR/domains.txt
        fi
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
        if ! systemctl status crond.service >/dev/null 2>&1; then
            systemctl start crond
        fi
    fi

    local PROGRAM=$BASE_DIR/sbin/renew_cert.sh
    if crontab -l 2>/dev/null | grep -qF $PROGRAM ;then
        return;
    fi

    local day=`date +%e`;
    day=${day## }
    if [ "$day" -gt 28 ];then
        day=28
    fi

    local CRONTAB_CMD="#每周日凌晨4:15 更新ssl证书
15 4 $day * * $PROGRAM > $BASE_DIR/log/dehydrated.log 2>&1 &"

    echo "$CRONTAB_CMD" | crontab -

    if crontab -l 2>/dev/null | grep -qF $PROGRAM ;then
        return;
    else
        echo "fail to add crontab $PROGRAM" >&2
        return 1
    fi
}
# }}}

# {{{ function mod_php_config_mysql_password() php配置文件中mysql密码修改在这里
function mod_php_config_mysql_password()
{
    local password=$1

    # 修改php配置文件中的mysql密码
    local PHP_CONF=$BASE_DIR/conf/config.php
    if [ ! -f "$PHP_CONF" ];then
        echo "Can't find file: $PHP_CONF . Please manually modify the mysql root password. " >&2;
        return 1;
    fi
    local mysql_user=`$PHP_BASE/bin/php -r "require('$PHP_CONF'); echo MYSQL_USER;"`;
    if [ "$mysql_user" = "root" ];then
        sed -i.bak.$$ "s/define('MYSQL_PASS', '[^'\"]\{1,\}')/define('MYSQL_PASS', '$password')/" $PHP_CONF
        rm -rf ${PHP_CONF}.bak.*
    fi
}
# }}}
# {{{ function sql_init() mysql数据库初始化在这里
function sql_init()
{
    local password=$1

    if [ -d "$curr_dir/sql" ];then
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
            $MYSQL_BASE/bin/mysql -uroot -p"$password" -S $MYSQL_RUN_DIR/mysql.sock < ${sql_file_array[$i]} 2>/dev/null

            if [ "$?" != "0" ];then
                echo "Failed to initialize the mysql database. sql file: ${sql_file_array[$i]}" >&2;
                return 1;
            fi
        done;
    fi
}
# }}}


##################################################################
#                         BASE_DIR                               #
##################################################################

if ! has_chown_finished ; then
    chown -R root:root $BASE_DIR
fi

##################################################################
#                         logrotate conf file                    #
##################################################################

sed -i "s%LOG_DIR%${LOG_DIR}%"  $BASE_DIR/etc/eo_logrotate.conf
sed -i "s%RUN_DIR%${$BASE_DIR}/run%" $BASE_DIR/etc/eo_logrotate.conf

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

##################################################################
#                         postgresql init                             #
##################################################################

postgresql_init
