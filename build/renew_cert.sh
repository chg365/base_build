#!/bin/bash

project=@project_abbreviation@
DEHYDRATED_BASE=@DEHYDRATED_BASE@
CONFIG_DIR=@DEHYDRATED_CONFIG_DIR@
NGINX_BASE=@NGINX_BASE@

# {{{ function delete_expire_cert_file() 删除过期的证书文件
function delete_expire_cert_file() {
    local CERTS_DIR=$CONFIG_DIR/certs

    if [ ! -d "$CERTS_DIR" ];then
        echo "证书目录不存在" >&2
        exit 1;
    fi

    local link_files=(
            "cert.csr"
            "cert.pem"
            "chain.pem"
            "fullchain.pem"
            "privkey.pem"
            )

    for domain_dir in `find $CERTS_DIR -mindepth 1 -maxdepth 1 -type d`; do
        for((i=0; i<${#link_files[*]}; i++)); do
            local file_name=${link_files[$i]}
            local link_file="$domain_dir/$file_name"
            if [ -h "$link_file" ];then
                local real_file=`realpath $link_file`
                local real_file_name="${real_file##*/}"
                local f;
                for f in `find $domain_dir -name "${file_name/./-*.}" -type f`; do
                    if [ "${f##*/}" != "$real_file_name" ]; then
                        rm -f ${f}
                    fi
                done
            fi
        done
    done
}
# }}}

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

if  which systemctl >/dev/null 2>&1 && [ -f /usr/lib/systemd/system/${project}.nginx.service ]; then
    #if systemctl status chg_base.nginx >/dev/null ; then
        systemctl reload ${project}.nginx.service
    #fi
else
    $NGINX_BASE/sbin/nginx -s reload
fi

delete_expire_cert_file

# 测试证书是否生效
# echo | openssl s_client -connect your.domain.com:443 | openssl x509 -noout -dates
