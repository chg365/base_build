#!/bin/bash

DEHYDRATED_BASE=$DEHYDRATED_BASE
CONFIG_DIR=$DEHYDRATED_CONFIG_DIR
NGINX_BASE=$NGINX_BASE

if [ ! -d "$CONFIG_DIR/accounts" ] || ! test -f `find $CONFIG_DIR/accounts/ -name account_key.pem` ; then
    $DEHYDRATED_BASE/sbin/dehydrated --register --accept-terms -f $CONFIG_DIR/config
    flag1=$?
    if [ "$flag1" != "0" ];then
        echo "dehydrated --register faild. return: $flag1" >&2
        exit 1
    fi
fi

# -x 强制更新
res=`$DEHYDRATED_BASE/sbin/dehydrated -c -f $CONFIG_DIR/config`
flag2=$?

if [ "$flag2" != "0" ]; then
    echo "dehydrated -c faild. return: $flag2" >&2
    exit 1;
fi
# 重启nginx
num1=`echo "$res"| grep -c 'Skipping renew!'`
num2=`echo "$res"| grep -c '^Processing '`
if [ "$num1" -gt "0" -a "$num1" = "$num2" ] ;then
    exit;
fi

# 强制使用https
sed -n ''
#ssl_certificate      /usr/local/chg/base/etc/dehydrated/certs/mochoua.com/fullchain.pem;
#ssl_certificate_key  /usr/local/chg/base/etc/dehydrated/certs/mochoua.com/privkey.pem;

 #return 301 https:

$NGINX_BASE/sbin/nginx -s reload

# 测试证书是否生效
# echo | openssl s_client -connect your.domain.com:443 | openssl x509 -noout -dates
