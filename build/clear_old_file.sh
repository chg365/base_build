#!/bin/bash
# {{{ function_exists() 检测函数是否定义
function_exists()
{
    type -t "$1" 2>/dev/null|grep -q 'function'
    if [ "$?" != "0" ];then
        return 1;
    fi
    return 0;
}
# }}}
# {{{ delete_soft_old_file()
delete_soft_old_file()
{
    is_echo_latest=0

    local array=(
            cacert
            clamav
            python
            xunsearch_sdk
            xunsearch
            scws
            fribidi
            libwebp
            xapian_core
            xapian_omega
            xapian_bindings
            browscap_ini
            nghttp2
            calibre
            gitbook
            gitbook_cli
            nodejs
            logrotate
            dehydrated
            patchelf
            tesseract
            ckeditor
            composer
            php_memcached
            apache
            apr
            apr_util
            pgbouncer
            postgresql
            libsodium
            pango
            poppler
            fontconfig
            expat
            cairo
            pixman
            jpeg
            libgd
            qrencode
            libmemcached
            memcached
            kerberos
            imap
            inputproto
            xextproto
            xproto
            xtrans
            libXau
            libX11
            libpthread_stubs
            libxcb
            xcb_proto
            macros
            xf86bigfontproto
            kbproto
            libXpm
            libXext
            libmcrypt
            libwbxml
            libxslt
            libxml2
            gettext
            readline
            libiconv
            libjpeg
            pcre
            boost
            gearmand
            libevent
            curl
            fontforge
            libpng
            util_linux
            glib
            freetype
            harfbuzz
            nasm
            json
            libfastjson
            nginx
            stunnel
            rsyslog
            libuuid
            liblogging
            libgcrypt
            libgpg_error
            libestr
            hiredis
            redis
            libunwind
            zeromq
            sqlite
            swoole
            psr
            openssl
            icu
            zlib
            libzip
            gmp
            php
            mysql
            imagemagick
            pkgconfig
            re2c
            tidy
            sphinx
            php_sphinx
            openjpeg
            pdf2htmlEX

            php_gearman
            php_grpc
            php_protobuf
            pthreads
            parallel
            zip
            solr
            mailparse
            amqp
            pecl_http
            propro
            raphf
            apcu
            apcu_bc
            php_libevent
            event
            xdebug
            dio
            trader
            php_qrencode
            php_mongodb
            php_zmq
            php_redis
            imagick
            phalcon
            yaf
            php_libsodium
            fann

            smarty
            yii2_smarty
            parseapp
            jquery
            jquery3
            d3
            chartjs
            htmlpurifier
            rabbitmq_c
            libmaxminddb
            maxmind_db_reader_php
            web_service_common_php
            geoip2_php
            geoipupdate
            electron
            phantomjs
            laravel
            yii2
            laravel_framework

            nginx_upload_module
            nginx_upload_progress_module
            nginx_push_stream_module
            nginx_http_geoip2_module
            nginx_sticky_module
            nginx_incubator_pagespeed

            );
    for i in ${array[@]};
    do
        delete_old_file $i
    done
}
# }}}
# {{{ delete all soft old file
# {{{ delete_old_file()
delete_old_file()
{
    local soft=${1}
    if [ "$soft" = "" ];
    then
        echo "soft name is empty!" >&2
        return 1;
    fi
    local func_name="delete_${soft}_old_file";



    function_exists "$func_name";

    if [ "$?" = "0" ];
    then
        $func_name
        return $?
    fi
    local U_SOFT=`echo -n ${soft} | tr '[a-z]' '[A-Z]'`;
    local file_version="${U_SOFT}_VERSION"
    local file_name="${U_SOFT}_FILE_NAME"

    if [ "${!file_version}" = "" -o "${!file_name}" = "" ];
    then
        echo "${soft} version or file name is empty !" >&2
        return 1;
    fi
    delete_default_old_file ${!file_version} ${!file_name}
    return $?;
}
# }}}
# {{{ delete_default_old_file()
delete_default_old_file()
{
    local file_version=$1
    local file_name=$2

    local pre="${file_name%%${file_version}*}";
    local sub="${file_name##*${file_version}}";

    #find $PKGS_DIR -mindepth 1 -maxdepth 1 -depth \( -name $file_name -prune \) -o -name "${pre}*${sub}" -print
    find $PKGS_DIR -mindepth 1 -maxdepth 1 -depth \( -name $file_name -prune \) -o -name "${pre}*${sub}" -delete
}
# }}}
# {{{ delete_icu_old_file()
delete_icu_old_file()
{
    local ICU_VERSION="${ICU_VERSION//./_}"
    delete_default_old_file ${ICU_VERSION} ${ICU_FILE_NAME}
}
# }}}
#}}}

curr_dir=$(cd "$(dirname "$0")"; pwd);
#otool -L
#brew install

base_define_file=$curr_dir/base_define.sh

if [ ! -f $base_define_file ]; then
echo "can't find base_define.sh";
exit 1;
fi

. $base_define_file

delete_soft_old_file
#delete_old_file icu
