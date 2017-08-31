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
# {{{ function nginx_user_init()
function nginx_user_init()
{
    grep -q "^${NGINX_GROUP}:" /etc/group
    if [ "$?" != 0 ]; then
        groupadd $NGINX_GROUP
    fi

    grep -q "^${NGINX_USER}:" /etc/passwd
    if [ "$?" != 0 ]; then
        useradd -r -M -g $NGINX_GROUP -s $(grep 'nologin' /etc/shells|head -1) $NGINX_USER
    fi
}
# }}}

mkdir -p $BASE_DIR/run/nginx
mkdir -p $TMP_DATA_DIR/nginx
mkdir -p $NGINX_LOG_DIR

nginx_user_init
#chown -R $NGINX_USER:$NGINX_GROUP $BASE_DIR/run/nginx
chown -R $NGINX_USER:$NGINX_GROUP $TMP_DATA_DIR/nginx $NGINX_LOG_DIR

if [ ! -d "$DEHYDRATED_CONFIG_DIR" ];then
    echo "domains.txt目录不存在" >&2
    exit 1;
fi

if [ -f "$DEHYDRATED_CONFIG_DIR/domains.txt" ]; then
    #echo `date +%Y%m%d-%H%M%S`
    touch $DEHYDRATED_CONFIG_DIR/domains.txt
fi

while read -t30 -p 'Please input domains: [Ctrl + D] or [quit] is finished\x0a    Example: example.com www.example.com' line;
do
    if [ "$line" == "quit" -o "$line" = "exit" ]; then
        break;
    fi
    echo $line >> $DEHYDRATED_CONFIG_DIR/domains.txt
done

#启动nginx服务
$NGINX_BASE/sbin/nginx

echo "Start create certificates ...."
$BASE_DIR/sbin/renew_cert.sh
if [ ! -d "$DEHYDRATED_CONFIG_DIR/certs" ];then
    echo "Create certificates faild." >&2
    $NGINX_BASE/sbin/nginx -s stop
    exit 1;
fi
$NGINX_BASE/sbin/nginx -s stop
domain=""
domains1=`cat $DEHYDRATED_CONFIG_DIR/domains.txt|head -1|tr ' ' '\n'`
domains2=`find $DEHYDRATED_CONFIG_DIR/certs/ -maxdepth 1 -mindepth 1 -type d|xargs -i basename {}|grep -v '^example.com$'`;
for i in `echo "$domains1"`;
do
    for j in `echo ""`;
    do
        if [ "$i" = "$j" ];then
            domain=$i;
            break 2;
        fi
    done
done
if [ "$domain" = "" ];then
    echo "get domain name faild." >&2
    exit 1;
fi
# 更改nginx使用的证书
sed -i.bak.$$ "s/example.com/$domain/" $NGINX_CONFIG_DIR/conf/nginx.conf
rm -rf $NGINX_CONFIG_DIR/conf/nginx.conf.bak.*
