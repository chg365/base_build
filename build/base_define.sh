#!/bin/sh
# https://github.com/cockroachdb/cockroach
# https://github.com/pingcap/tidb
# https://github.com/pingcap/docs-cn

curr_dir=$(cd "$(dirname "$0")"; pwd);
project_name_file=${curr_dir}/project_name.sh

if [ ! -f "$project_name_file" ];then
    echo "$project_name_file is not file!" >&2
    exit 1;
fi

. $project_name_file

#HOSTTYPE=x86_64
#OSTYPE=linux-gnu
# MAC 不支持 declare -l
#declare -l OS_NAME
#declare -l HOST_TYPE
# getconf LONG_BIT # 32 64
OS_NAME=`uname -s|tr '[A-Z]' '[a-z]'`;   # Linux

# uname -s # Linux -
# uname -o # GNU/Linux -
# uname -i # x86_64 aarch64
# uname -m # x86_64 aarch64
# uname -p # x86_64 aarch64
# uname -r # 3.10.0-957.21.3.el7.x86_64 4.4.13-20161128.kylin.5.server+
HOST_TYPE=`uname -m|tr '[A-Z]' '[a-z]'`; # x86_64 # uname -p # uname -i # sw_64 申威 # mips64el 龙芯
KERNEL_RELEASE=`uname -r` # 3.10.0-229.el7.x86_64 # 4.4.15-aere+ 申威 # 3.10.0-862.9.1.ns7_4.45.mips64el
KERNEL_RELEASE=`echo $KERNEL_RELEASE |sed -n 's/^[0-9.-]\{1,\}\.//p'`;
KERNEL_RELEASE=${KERNEL_RELEASE%%.*}
# 3.10.0-693.21.1.el7.x86_64
# 5.3.11-1.el7.elrepo.x86_64
KERNEL_RELEASE=${KERNEL_RELEASE%.*}

CPU_CORE_NUM=0; #通过get_cpu_core_num 设置
MAKE_JOBS=1; # make -j 的参数

BASE_DIR=/opt/${project_abbreviation//_//}
COMPILE_BASE=$(dirname $BASE_DIR)/compile

CONTRIB_BASE=$BASE_DIR/contrib
ETC_BASE=$BASE_DIR/etc
OPT_BASE=$BASE_DIR/opt
WEB_BASE=$BASE_DIR/web
SSL_CONFIG_DIR=$ETC_BASE/ssl
JS_BASE=$WEB_BASE/public/js
CSS_BASE=$WEB_BASE/public/css

# {{{ open source libray info
# {{{ open source libray install base dir
ONIGURUMA_BASE=$OPT_BASE/oniguruma
READLINE_BASE=$OPT_BASE/readline
PATCHELF_BASE=$CONTRIB_BASE
TESSERACT_BASE="$OPT_BASE/tesseract"
RE2C_BASE="$COMPILE_BASE"
PCRE_BASE=$OPT_BASE/pcre
PCRE2_BASE=$OPT_BASE/pcre2
OPENSSL_BASE=$OPT_BASE/openssl
CACERT_BASE="$SSL_CONFIG_DIR/certs/"
HIREDIS_BASE=$CONTRIB_BASE
ZLIB_BASE=$CONTRIB_BASE
CURL_BASE=$CONTRIB_BASE
NGHTTP2_BASE=$CONTRIB_BASE
ICU_BASE=$OPT_BASE/icu
LIBZIP_BASE=$CONTRIB_BASE
GETTEXT_BASE=$OPT_BASE/gettext
LIBICONV_BASE=$CONTRIB_BASE
LIBXML2_BASE=$OPT_BASE/libxml2
LIBWEBP_BASE=$CONTRIB_BASE
JSON_BASE=$CONTRIB_BASE
LIBFASTJSON_BASE=$CONTRIB_BASE
LIBMCRYPT_BASE=$CONTRIB_BASE
LIBWBXML_BASE=$CONTRIB_BASE
PKGCONFIG_BASE=$CONTRIB_BASE
LIBGD_BASE=$CONTRIB_BASE
IMAGEMAGICK_BASE=$OPT_BASE/ImageMagick
JPEG_BASE=$OPT_BASE/jpeg # 和libjpeg-turbo文件名冲突不能在同一个目录下
LIBXPM_BASE=$CONTRIB_BASE
LIBXEXT_BASE=$CONTRIB_BASE
IMAP_BASE=$OPT_BASE/imap
KERBEROS_BASE=$OPT_BASE/kerberos
GMP_BASE=$CONTRIB_BASE
LIBMEMCACHED_BASE=$CONTRIB_BASE
LIBEVENT_BASE=$CONTRIB_BASE
QRENCODE_BASE=$CONTRIB_BASE
LIBSODIUM_BASE=$CONTRIB_BASE
#ZEROMQ_BASE=$OPT_BASE/zeromq
ZEROMQ_BASE=$CONTRIB_BASE
LIBUNWIND_BASE=$CONTRIB_BASE
BOOST_BASE=$OPT_BASE/boost
MEMCACHED_BASE=$OPT_BASE/memcached
REDIS_BASE=$OPT_BASE/redis
GEARMAND_BASE=$OPT_BASE/gearmand
RABBITMQ_C_BASE=$CONTRIB_BASE
LIBXSLT_BASE=$OPT_BASE/libxslt
TIDY_BASE=$CONTRIB_BASE
SPHINX_BASE=$OPT_BASE/sphinx
#SPHINX_CLIENT_BASE=$SPHINX_BASE
SPHINX_CLIENT_BASE=$OPT_BASE/sphinx_client

SCWS_BASE=$OPT_BASE/scws
XAPIAN_CORE_SCWS_BASE=$OPT_BASE/xapian-scws
XUNSEARCH_BASE=$OPT_BASE/xunsearch

XAPIAN_CORE_BASE="$OPT_BASE/xapian"
XAPIAN_OMEGA_BASE="$OPT_BASE/omega"
XAPIAN_BINDINGS_BASE="$OPT_BASE/xapian-bindings"

CLAMAV_BASE="$OPT_BASE/clamav"
FANN_BASE="$OPT_BASE/libfann"

FRIBIDI_BASE=$CONTRIB_BASE
LIBPNG_BASE=$CONTRIB_BASE
NASM_BASE=$CONTRIB_BASE
LIBJPEG_BASE=$CONTRIB_BASE
OPENJPEG_BASE=$CONTRIB_BASE
CAIRO_BASE=$OPT_BASE/cairo
PIXMAN_BASE=$CONTRIB_BASE
EXPAT_BASE=$CONTRIB_BASE
FREETYPE_BASE=$CONTRIB_BASE
GLIB_BASE=$OPT_BASE/glib
UTIL_LINUX_BASE=$OPT_BASE/util_linux
LIBFFI_BASE=$CONTRIB_BASE
HARFBUZZ_BASE=$OPT_BASE/harfbuzz
FONTCONFIG_BASE=$CONTRIB_BASE
POPPLER_BASE=$CONTRIB_BASE
PANGO_BASE=$CONTRIB_BASE
FONTFORGE_BASE=$OPT_BASE/fontforge
PDF2HTMLEX_BASE=$OPT_BASE/pdf2htmlex
#if [ "$OS_NAME" = 'darwin' ];then
LIBX11_BASE=$OPT_BASE/libx11
XPROTO_BASE=$LIBX11_BASE
MACROS_BASE=$LIBX11_BASE
XCB_PROTO_BASE=$LIBX11_BASE
LIBPTHREAD_STUBS_BASE=$LIBX11_BASE
LIBXAU_BASE=$LIBX11_BASE
LIBXCB_BASE=$LIBX11_BASE
KBPROTO_BASE=$LIBX11_BASE
INPUTPROTO_BASE=$LIBX11_BASE
XEXTPROTO_BASE=$LIBX11_BASE
XTRANS_BASE=$LIBX11_BASE
XF86BIGFONTPROTO_BASE=$CONTRIB_BASE
#fi

SQLITE_BASE=$CONTRIB_BASE
POSTGRESQL_BASE=$OPT_BASE/pgsql
PGBOUNCER_BASE=$OPT_BASE/pgbouncer

APR_BASE=$CONTRIB_BASE
APR_UTIL_BASE=$CONTRIB_BASE


NODEJS_BASE=$OPT_BASE/nodejs
CALIBRE_BASE="$OPT_BASE/calibre"
GITBOOK_BASE="$NODEJS_BASE/lib/node_modules/gitbook"
GITBOOK_CLI_BASE="$NODEJS_BASE/lib/node_modules/gitbook-cli"
APACHE_BASE=$OPT_BASE/apache
NGINX_BASE=$OPT_BASE/nginx
STUNNEL_BASE=$OPT_BASE/stunnel
RSYSLOG_BASE=$OPT_BASE/rsyslog
LOGROTATE_BASE="$CONTRIB_BASE"
LIBUUID_BASE="$CONTRIB_BASE"
LIBLOGGING_BASE=$CONTRIB_BASE
LIBGCRYPT_BASE=$OPT_BASE/libgcrypt
LIBGPG_ERROR_BASE=$CONTRIB_BASE
LIBESTR_BASE=$CONTRIB_BASE
MYSQL_BASE=$OPT_BASE/mysql
PHP_BASE=$OPT_BASE/php
PYTHON_BASE="$OPT_BASE/python"


GRPC_BASE="$CONTRIB_BASE"
CODEIGNITER_BASE=$BASE_DIR/inc/codeigniter
ZEND_BASE=$BASE_DIR/inc/zend
YII2_BASE=$BASE_DIR/inc/yii2
SMARTY_BASE=$BASE_DIR/inc/smarty
YII2_SMARTY_BASE=$BASE_DIR/inc/yii2/yiisoft/yii2/smarty
PARSEAPP_BASE=$BASE_DIR/inc/parse-app
HTMLPURIFIER_BASE=$BASE_DIR/inc/htmlpurifier
COMPOSER_BASE="$BASE_DIR/inc"
LARAVEL_BASE=$BASE_DIR/inc/laravel

CKEDITOR_BASE=$JS_BASE/ckeditor
JQUERY_BASE=$JS_BASE/
D3_BASE=$JS_BASE/
CHARTJS_BASE=$JS_BASE/
FAMOUS_BASE=$JS_BASE/famous
SWFUPLOAD_BASE=$JS_BASE/swfupload

# 编译nginx的geoip2模块时，影响http_upload模块，单独放到一个目录下没有问题，应该是有其他lib影响了。
LIBMAXMINDDB_BASE=$OPT_BASE/libmaxminddb
GEOIPUPDATE_BASE=$CONTRIB_BASE
ELECTRON_BASE=$OPT_BASE/electron
PHANTOMJS_BASE=$OPT_BASE/phantomjs
DEHYDRATED_BASE=$CONTRIB_BASE

# }}}
# {{{ open source libray version info
PKGCONFIG_VERSION="0.29.2"
RE2C_VERSION="1.1.1"
PATCHELF_VERSION="0.10"
TESSERACT_VERSION="4.1.1"
READLINE_VERSION="8.0"
ONIGURUMA_VERSION="6.9.4"

PCRE_VERSION="8.43"
PCRE2_VERSION="10.34" # pcre2 编译apache时报错
OPENSSL_VERSION="1.1.1d"
CACERT_VERSION="2020-01-01"
HIREDIS_VERSION="0.14.0"
ZLIB_VERSION="1.2.11" # www.zlib.net
NGHTTP2_VERSION="1.40.0"
CURL_VERSION="7.68.0"
ICU_VERSION="58.2" # 59.1 gcc要4.4.8以上
if [ "$OS_NAME" != 'darwin' ];then
    gcc_minimum_version="4.4.7"
    gcc_version=`gcc --version 2>/dev/null|head -1|awk '{ print $3;}'`;
    gcc_new_version=`echo $gcc_version $gcc_minimum_version|tr " " "\n"|sort -rV|head -1`;
    if [ "$gcc_new_version" = "$gcc_minimum_version" ]; then
        ICU_VERSION="58.2"
    else
        ICU_VERSION="65.1" #升级到 59.1后 PHP7.1.8的intl扩展编译不过去 60.2 php 7.2.0编译不过去
    fi
fi
LIBZIP_VERSION="1.3.2" # 1.4.0 需要cmake 3.0.2
which cmake 1>/dev/null 2>/dev/null
if [ "$?" = "0" ];then
    cmake_version=`cmake --version 2>/dev/null|head -1|awk '{ print $NF;}'`;
    cmake_new_version=`echo $cmake_version 3.0.1|tr " " "\n"|sort -rV|head -1`;
    if [ "$cmake_new_version" != "3.0.1" ]; then
        LIBZIP_VERSION="1.5.2"
    fi
fi
GETTEXT_VERSION="0.20.1"
LIBICONV_VERSION="1.16"
LIBXML2_VERSION="2.9.10"
LIBWEBP_VERSION="1.1.0"
JSON_VERSION="0.13.1"
LIBFASTJSON_VERSION="0.99.8"
LIBMCRYPT_VERSION="2.5.8"
LIBWBXML_VERSION="0.11.6"
LIBXPM_VERSION="3.5.13"
LIBXEXT_VERSION="1.3.4"
IMAP_VERSION="patches-FD29-RPM"
KERBEROS_VERSION="1.17.1"
GMP_VERSION="6.2.0"
LIBMEMCACHED_VERSION="1.0.18" # 1.0.17 php memcached编译不过去  1.0.16
LIBEVENT_VERSION="2.1.11"
QRENCODE_VERSION="4.0.2"
LIBXSLT_VERSION="1.1.34"
TIDY_VERSION="5.7.28"
SPHINX_VERSION="2.2.11"
PHP_SPHINX_VERSION="php7"

SCWS_VERSION="1.2.3"
XAPIAN_CORE_SCWS_VERSION="1.4.13"
XUNSEARCH_VERSION="1.4.14"
XUNSEARCH_SDK_VERSION="1.4.14"
XUNSEARCH_FULL_VERSION="1.4.14"

XAPIAN_CORE_VERSION="1.4.14"
XAPIAN_OMEGA_VERSION="1.4.13" # 使用scws 的xapian
XAPIAN_BINDINGS_VERSION="1.4.13" # 使用scws 的xapian

CLAMAV_VERSION="0.102.1"
FANN_VERSION="2.2.0"

FRIBIDI_VERSION="1.0.8"
LIBGD_VERSION="2.2.5"
IMAGEMAGICK_VERSION="7.0.9-17"
JPEG_VERSION="9d"
LIBPNG_VERSION="1.6.37"
NASM_VERSION="2.14.02"
LIBJPEG_VERSION="2.0.4"
OPENJPEG_VERSION="2.3.1"
CAIRO_VERSION="1.14.6"
PIXMAN_VERSION="0.38.4"
EXPAT_VERSION="2.2.9"
FREETYPE_VERSION="2.10.1"
GLIB_VERSION="2.58.3" #2.60是用的meson ninja, 而不是configure make
UTIL_LINUX_VERSION="2.35"
LIBFFI_VERSION="3.2.1"
HARFBUZZ_VERSION="2.4.0"
FONTCONFIG_VERSION="2.13.92"
POPPLER_VERSION="0.57.0" #0.58.0 0.59.0 编译 pdf2htmlEX时报错 0.14.6;
which cmake 1>/dev/null 2>/dev/null
if [ "$?" = "0" ];then
    cmake_version=`cmake --version 2>/dev/null|head -1|awk '{ print $NF;}'`;
    cmake_new_version=`echo $cmake_version 3.0.999|tr " " "\n"|sort -rV|head -1`;
    #  0.60.1需要CMake 3.1.0
    if [ "$cmake_new_version" != "3.0.999" ]; then
        POPPLER_VERSION="0.84.0"
    fi
fi
PANGO_VERSION="1.42.4" # pango 1.43.0 要求 meson_version : '>= 0.48.0',编译不上
FONTFORGE_VERSION="20190801"
PDF2HTMLEX_VERSION="0.14.6"
#if [ "$OS_NAME" = 'darwin' ];then
LIBX11_VERSION="1.6.9"
XPROTO_VERSION="7.0.31"
MACROS_VERSION="1.19.2"
XCB_PROTO_VERSION="1.13"
LIBPTHREAD_STUBS_VERSION="0.4"
LIBXAU_VERSION="1.0.9"
LIBXCB_VERSION="1.13.1"
KBPROTO_VERSION="1.0.7"
INPUTPROTO_VERSION="2.3.2"
XEXTPROTO_VERSION="7.3.0"
XTRANS_VERSION="1.4.0"
XF86BIGFONTPROTO_VERSION="1.2.0"
#fi

LIBSODIUM_VERSION="1.0.18"
ZEROMQ_VERSION="4.3.2"
LIBUNWIND_VERSION="1.3.1"
RABBITMQ_C_VERSION="0.10.0" # 0.9.0 编译不过去，退回到0.8.0
PHP_ZMQ_VERSION="1.1.4" #1.1.3

SQLITE_VERSION="3300100"
POSTGRESQL_VERSION="12.1"
PGBOUNCER_VERSION="1.12.0"

APR_VERSION="1.7.0"
APR_UTIL_VERSION="1.6.1"

APACHE_VERSION="2.4.41"
MYSQL_VERSION="8.0.19"
BOOST_VERSION="1_66_0" # 1_61_0
NGINX_VERSION="1.16.1"
STUNNEL_VERSION="5.56"
NODEJS_VERSION="13.7.0"
CALIBRE_VERSION="4.8.0"
GITBOOK_VERSION="3.2.2"
GITBOOK_CLI_VERSION="2.3.2"
RSYSLOG_VERSION="8.2001.0"
LOGROTATE_VERSION="3.15.1"
LIBUUID_VERSION="1.0.3"
LIBLOGGING_VERSION="1.0.6"
LIBGCRYPT_VERSION="1.8.5"
LIBGPG_ERROR_VERSION="1.36"
LIBESTR_VERSION="0.1.11"
PHP_VERSION="7.4.1" #7.3.12 有内存溢出风险，回退到7.2
COMPOSER_VERSION="1.9.2"
BROWSCAP_INI_VERSION="6000036"
PYTHON_VERSION="3.7.6"

if [ `echo "${PHP_VERSION}" "7.1.99"|tr " " "\n"|sort -rV|head -1` = "7.1.99" ]; then
    PHP_LIBSODIUM_VERSION="1.0.7"
else
    PHP_LIBSODIUM_VERSION="2.0.22"
fi
MEMCACHED_VERSION="1.5.21"
PHP_MEMCACHED_VERSION="3.1.5"
REDIS_VERSION="5.0.7"
GEARMAND_VERSION="1.1.18"
EVENT_VERSION="2.5.3"
DIO_VERSION="0.1.0"
TRADER_VERSION="0.5.0"
PHP_LIBEVENT_VERSION="0.1.0"
APCU_VERSION="5.1.18"
APCU_BC_VERSION="1.0.5"
YAF_VERSION="3.0.9"
PHALCON_VERSION="4.0.2"
XDEBUG_VERSION="2.9.1"
RAPHF_VERSION="2.0.1"
PROPRO_VERSION="2.1.0"
PECL_HTTP_VERSION="3.2.3"
AMQP_VERSION="1.9.4"
MAILPARSE_VERSION="3.0.4"
PHP_REDIS_VERSION="5.1.1"
PHP_GEARMAN_VERSION="2.0.6"
PHP_MONGODB_VERSION="1.6.1"
PHP_FANN_VERSION="1.1.1"
SOLR_VERSION="2.5.0"
IMAGICK_VERSION="3.4.4"
PTHREADS_VERSION="3.2.0"
PARALLEL_VERSION="1.1.3"
ZIP_VERSION="1.15.5"
SWOOLE_VERSION="4.4.15"
PSR_VERSION="0.7.0"
PHP_PROTOBUF_VERSION="3.11.2"
PHP_GRPC_VERSION="1.26.0"
#PHP_QRENCODE_VERSION="0.0.3"
PHP_QRENCODE_VERSION="0.1.0"

ZEND_VERSION="2.4.9"
YII2_VERSION="2.0.32"
SMARTY_VERSION="3.1.34"
YII2_SMARTY_VERSION="2.0.9"
PARSEAPP_VERSION="1.1"
HTMLPURIFIER_VERSION="4.12.0"
LARAVEL_VERSION="6.12.0"
LARAVEL_FRAMEWORK_VERSION="6.12.0"

CKEDITOR_VERSION="4.13.1"
JQUERY_VERSION="1.12.4.min"
JQUERY3_VERSION="3.4.1.min"
D3_VERSION="5.15.0"
CHARTJS_VERSION="2.9.3"
FAMOUS_VERSION="0.3.5"
FAMOUS_FRAMEWORK_VERSION="0.13.1"
FAMOUS_ANGULAR_VERSION="0.5.2"
#SWFUpload%20v2.2.0.1%20Core.zip
#SWFUpload_v250_beta_3_core.zip
SWFUPLOAD_VERSION="2.2.0.1"


LIBMAXMINDDB_VERSION="1.4.2"
MAXMIND_DB_READER_PHP_VERSION="1.6.0"
WEB_SERVICE_COMMON_PHP_VERSION="0.6.0"
GEOIP2_PHP_VERSION="2.10.0"
GEOIPUPDATE_VERSION="3.1.1" # 4以后改成golang了
ELECTRON_VERSION="7.1.9"
if [ "$OS_NAME" = 'darwin' ];then
    PHANTOMJS_VERSION="2.1.1"
else
    PHANTOMJS_VERSION="1.9.7" # npm install gitbook-pdf -g 时用到这个版本，不能使用最新的版本
fi
DEHYDRATED_VERSION="0.6.5"

NGINX_UPLOAD_PROGRESS_MODULE_VERSION="0.9.2"
NGINX_HTTP_GEOIP2_MODULE_VERSION="3.3"
NGINX_PUSH_STREAM_MODULE_VERSION="0.5.4"
NGINX_STICKY_MODULE_VERSION="1.2.6"
NGINX_UPLOAD_MODULE_VERSION="2.3.0"
NGINX_INCUBATOR_PAGESPEED_VERSION="1.13.35.2"
PSOL_VERSION=$NGINX_INCUBATOR_PAGESPEED_VERSION

# }}}
# {{{ open source libray file name
ONIGURUMA_FILE_NAME="oniguruma-${ONIGURUMA_VERSION}.tar.gz"
READLINE_FILE_NAME="readline-${READLINE_VERSION}.tar.gz"
PATCHELF_FILE_NAME="patchelf-${PATCHELF_VERSION}.tar.gz"
TESSERACT_FILE_NAME="tesseract-${TESSERACT_VERSION}.tar.gz"
RE2C_FILE_NAME="re2c-${RE2C_VERSION}.tar.gz"
OPENSSL_FILE_NAME="openssl-${OPENSSL_VERSION}.tar.gz"
CACERT_FILE_NAME="cacert-${CACERT_VERSION}.pem"
HIREDIS_FILE_NAME="hiredis-${HIREDIS_VERSION}.tar.gz"
ICU_FILE_NAME="icu4c-${ICU_VERSION//./_}-src.tgz"
ZLIB_FILE_NAME="zlib-${ZLIB_VERSION}.tar.gz"
LIBZIP_FILE_NAME="libzip-${LIBZIP_VERSION}.tar.xz"
GETTEXT_FILE_NAME="gettext-${GETTEXT_VERSION}.tar.xz"
LIBICONV_FILE_NAME="libiconv-${LIBICONV_VERSION}.tar.gz"
LIBXML2_FILE_NAME="libxml2-${LIBXML2_VERSION}.tar.gz"
LIBWEBP_FILE_NAME="libwebp-${LIBWEBP_VERSION}.tar.gz"
JSON_FILE_NAME="json-c-${JSON_VERSION}.tar.gz"
LIBFASTJSON_FILE_NAME="libfastjson-${LIBFASTJSON_VERSION}.tar.gz"
LIBMCRYPT_FILE_NAME="libmcrypt-${LIBMCRYPT_VERSION}.tar.gz"
LIBWBXML_FILE_NAME="libwbxml-${LIBWBXML_VERSION}.tar.bz2"
PKGCONFIG_FILE_NAME="pkg-config-${PKGCONFIG_VERSION}.tar.gz"
SQLITE_FILE_NAME="sqlite-autoconf-${SQLITE_VERSION}.tar.gz"
CURL_FILE_NAME="curl-${CURL_VERSION}.tar.bz2"
NGHTTP2_FILE_NAME="nghttp2-${NGHTTP2_VERSION}.tar.xz"
MYSQL_FILE_NAME="mysql-${MYSQL_VERSION}-$([ "$OS_NAME" = "linux" ] && echo "${KERNEL_RELEASE##*.}" || echo "macos10.13")-x86_64.tar.gz" #不支持32位了
BOOST_FILE_NAME="boost_${BOOST_VERSION}.tar.bz2"
PCRE_FILE_NAME="pcre-${PCRE_VERSION}.tar.bz2"
PCRE2_FILE_NAME="pcre2-${PCRE2_VERSION}.tar.bz2"
NGINX_FILE_NAME="nginx-${NGINX_VERSION}.tar.gz"
STUNNEL_FILE_NAME="stunnel-${STUNNEL_VERSION}.tar.gz"
NODEJS_FILE_NAME="node-v${NODEJS_VERSION}-$OS_NAME-x$( [ "$HOST_TYPE" = "x86_64" ] && echo "64" || echo "86" ).tar.$( [ "$OS_NAME" = "darwin" ] && echo "g" || echo "x" )z"
CALIBRE_FILE_NAME="calibre-${CALIBRE_VERSION}$( [ "$OS_NAME" = "linux" ] && echo "-${HOST_TYPE}.txz" || echo ".dmg")"
GITBOOK_FILE_NAME="gitbook-${GITBOOK_VERSION}.tar.gz"
GITBOOK_CLI_FILE_NAME="gitbook-cli-${GITBOOK_CLI_VERSION}.tar.gz"
RSYSLOG_FILE_NAME="rsyslog-${RSYSLOG_VERSION}.tar.gz"
LOGROTATE_FILE_NAME="logrotate-${LOGROTATE_VERSION}.tar.gz"
LIBUUID_FILE_NAME="libuuid-${LIBUUID_VERSION}.tar.gz"
LIBLOGGING_FILE_NAME="liblogging-${LIBLOGGING_VERSION}.tar.gz"
LIBGCRYPT_FILE_NAME="libgcrypt-${LIBGCRYPT_VERSION}.tar.bz2"
LIBGPG_ERROR_FILE_NAME="libgpg-error-${LIBGPG_ERROR_VERSION}.tar.gz"
LIBESTR_FILE_NAME="libestr-${LIBESTR_VERSION}.tar.gz"
PHP_FILE_NAME="php-${PHP_VERSION}.tar.xz"
PYTHON_FILE_NAME="Python-${PYTHON_VERSION}.tar.xz"
COMPOSER_FILE_NAME="composer-${COMPOSER_VERSION}.tar.gz"
BROWSCAP_INI_FILE_NAME="browscap-${BROWSCAP_INI_VERSION}.ini"
PTHREADS_FILE_NAME="pthreads-${PTHREADS_VERSION}.tar.gz"
PARALLEL_FILE_NAME="parallel-${PARALLEL_VERSION}.tgz"
ZIP_FILE_NAME="zip-${ZIP_VERSION}.tgz"
SWOOLE_FILE_NAME="swoole-${SWOOLE_VERSION}.tgz"
PSR_FILE_NAME="psr-${PSR_VERSION}.tgz"
PHP_PROTOBUF_FILE_NAME="protobuf-${PHP_PROTOBUF_VERSION}.tgz"
PHP_GRPC_FILE_NAME="grpc-${PHP_GRPC_VERSION}.tgz"
LIBPNG_FILE_NAME="libpng-${LIBPNG_VERSION}.tar.xz"
PIXMAN_FILE_NAME="pixman-${PIXMAN_VERSION}.tar.gz"
CAIRO_FILE_NAME="cairo-${CAIRO_VERSION}.tar.xz"
NASM_FILE_NAME="nasm-${NASM_VERSION}.tar.xz"
JPEG_FILE_NAME="jpegsrc.v${JPEG_VERSION}.tar.gz"
LIBXSLT_FILE_NAME="libxslt-${LIBXSLT_VERSION}.tar.gz"
TIDY_FILE_NAME="tidy-html5-${TIDY_VERSION}.tar.gz"
SPHINX_FILE_NAME="sphinx-${SPHINX_VERSION}-release.tar.gz"
PHP_SPHINX_FILE_NAME="pecl-search_engine-sphinx-${PHP_SPHINX_VERSION}.tar.gz"
SCWS_FILE_NAME="scws-${SCWS_VERSION}.tar.bz2"
SCWS_DICT_FILE_NAME="scws-dict-chs-utf8.tar.bz2"
XAPIAN_CORE_SCWS_FILE_NAME="xapian-core-scws-${XAPIAN_CORE_SCWS_VERSION}.tar.bz2"
XUNSEARCH_FULL_FILE_NAME="xunsearch-full-${XUNSEARCH_FULL_VERSION}.tar.bz2"
XUNSEARCH_FILE_NAME="xunsearch-${XUNSEARCH_VERSION}.tar.bz2"
XUNSEARCH_SDK_FILE_NAME="xunsearch-sdk-${XUNSEARCH_SDK_VERSION}.zip"

XAPIAN_CORE_FILE_NAME="xapian-core-${XAPIAN_CORE_VERSION}.tar.xz"
XAPIAN_OMEGA_FILE_NAME="xapian-omega-${XAPIAN_OMEGA_VERSION}.tar.xz"
XAPIAN_BINDINGS_FILE_NAME="xapian-bindings-${XAPIAN_BINDINGS_VERSION}.tar.xz"
CLAMAV_FILE_NAME="clamav-${CLAMAV_VERSION}.tar.gz"
FANN_FILE_NAME="fann-${FANN_VERSION}.tar.gz"

FRIBIDI_FILE_NAME="fribidi-${FRIBIDI_VERSION}.tar.gz"
LIBJPEG_FILE_NAME="libjpeg-turbo-${LIBJPEG_VERSION}.tar.gz"
if [ `echo "${OPENJPEG_VERSION%.*}" "2.1"|tr " " "\n"|sort -rV|head -1` = "2.1" ]; then
    #2.1.0及以前文件名是 openjpeg-version.2.1.tar.gz
    OPENJPEG_FILE_NAME="openjpeg-${OPENJPEG_VERSION/%.0/}.tar.gz"
else
    OPENJPEG_FILE_NAME="openjpeg-${OPENJPEG_VERSION}.tar.gz"
fi
FREETYPE_FILE_NAME="freetype-${FREETYPE_VERSION}.tar.xz"
GLIB_FILE_NAME="glib-${GLIB_VERSION}.tar.xz"
UTIL_LINUX_FILE_NAME="util-linux-${UTIL_LINUX_VERSION}.tar.xz"
LIBFFI_FILE_NAME="libffi-${LIBFFI_VERSION}.tar.gz"
HARFBUZZ_FILE_NAME="harfbuzz-${HARFBUZZ_VERSION}.tar.bz2"
EXPAT_FILE_NAME="expat-${EXPAT_VERSION}.tar.bz2"
FONTCONFIG_FILE_NAME="fontconfig-${FONTCONFIG_VERSION}.tar.xz"
POPPLER_FILE_NAME="poppler-${POPPLER_VERSION}.tar.xz"
FONTFORGE_FILE_NAME="fontforge-${FONTFORGE_VERSION}.tar.gz"
PDF2HTMLEX_FILE_NAME="pdf2htmlEX-${PDF2HTMLEX_VERSION}.tar.gz"
PANGO_FILE_NAME="pango-${PANGO_VERSION}.tar.xz"
LIBXPM_FILE_NAME="libXpm-${LIBXPM_VERSION}.tar.bz2"
LIBXEXT_FILE_NAME="libXext-${LIBXEXT_VERSION}.tar.bz2"
LIBGD_FILE_NAME="libgd-${LIBGD_VERSION}.tar.gz"
IMAGEMAGICK_FILE_NAME="ImageMagick-${IMAGEMAGICK_VERSION}.tar.xz"
GMP_FILE_NAME="gmp-${GMP_VERSION}.tar.xz"
IMAP_FILE_NAME="imap-${IMAP_VERSION}.tar.gz"
KERBEROS_FILE_NAME="krb5-${KERBEROS_VERSION}.tar.gz"
LIBMEMCACHED_FILE_NAME="libmemcached-${LIBMEMCACHED_VERSION}.tar.gz"
LIBEVENT_FILE_NAME="libevent-release-${LIBEVENT_VERSION}-stable.tar.gz"
QRENCODE_FILE_NAME="qrencode-${QRENCODE_VERSION}.tar.bz2"
POSTGRESQL_FILE_NAME="postgresql-${POSTGRESQL_VERSION}.tar.bz2"
PGBOUNCER_FILE_NAME="pgbouncer-${PGBOUNCER_VERSION}.tar.gz"
APR_FILE_NAME="apr-${APR_VERSION}.tar.gz"
APR_UTIL_FILE_NAME="apr-util-${APR_UTIL_VERSION}.tar.gz"
APACHE_FILE_NAME="httpd-${APACHE_VERSION}.tar.gz"
APCU_FILE_NAME="apcu-${APCU_VERSION}.tgz"
APCU_BC_FILE_NAME="apcu_bc-${APCU_BC_VERSION}.tgz"
YAF_FILE_NAME="yaf-${YAF_VERSION}.tar.gz"
PHALCON_FILE_NAME="cphalcon-${PHALCON_VERSION}.tar.gz"
XDEBUG_FILE_NAME="xdebug-${XDEBUG_VERSION}.tgz"
RAPHF_FILE_NAME="raphf-${RAPHF_VERSION}.tgz"
PROPRO_FILE_NAME="propro-${PROPRO_VERSION}.tgz"
PECL_HTTP_FILE_NAME="pecl_http-${PECL_HTTP_VERSION}.tgz"
AMQP_FILE_NAME="amqp-${AMQP_VERSION}.tgz"
MAILPARSE_FILE_NAME="mailparse-${MAILPARSE_VERSION}.tgz"
PHP_REDIS_FILE_NAME="redis-${PHP_REDIS_VERSION}.tgz"
PHP_GEARMAN_FILE_NAME="$( [ "$OS_NAME" != "darwin" ] && echo "pecl-gearman-" )gearman-${PHP_GEARMAN_VERSION}.tar.gz"
PHP_MONGODB_FILE_NAME="mongodb-${PHP_MONGODB_VERSION}.tgz"
PHP_FANN_FILE_NAME="fann-${PHP_FANN_VERSION}.tgz"
SOLR_FILE_NAME="solr-${SOLR_VERSION}.tgz"
MEMCACHED_FILE_NAME="memcached-${MEMCACHED_VERSION}.tar.gz"
PHP_MEMCACHED_FILE_NAME="memcached-${PHP_MEMCACHED_VERSION}.tgz"
REDIS_FILE_NAME="redis-${REDIS_VERSION}.tar.gz"
GEARMAND_FILE_NAME="gearmand-${GEARMAND_VERSION}.tar.gz"
EVENT_FILE_NAME="event-${EVENT_VERSION}.tgz"
DIO_FILE_NAME="dio-${DIO_VERSION}.tgz"
TRADER_FILE_NAME="trader-${TRADER_VERSION}.tgz"
PHP_LIBEVENT_FILE_NAME="libevent-${PHP_LIBEVENT_VERSION}.tgz"
IMAGICK_FILE_NAME="imagick-${IMAGICK_VERSION}.tgz"
PHP_QRENCODE_FILE_NAME="qrencode-${PHP_QRENCODE_VERSION}.tar.gz"
LIBSODIUM_FILE_NAME="libsodium-${LIBSODIUM_VERSION}.tar.gz"
ZEROMQ_FILE_NAME="zeromq-${ZEROMQ_VERSION}.tar.gz"
LIBUNWIND_FILE_NAME="libunwind-${LIBUNWIND_VERSION}.tar.gz"
RABBITMQ_C_FILE_NAME="rabbitmq-c-${RABBITMQ_C_VERSION}.tar.gz"
PHP_ZMQ_FILE_NAME="php-zmq-${PHP_ZMQ_VERSION}.tar.gz"
PHP_LIBSODIUM_FILE_NAME="libsodium-${PHP_LIBSODIUM_VERSION}.tgz"
ZEND_FILE_NAME="ZendFramework-${ZEND_VERSION}.tgz"
YII2_FILE_NAME="yii-basic-app-${YII2_VERSION}.tgz"
SMARTY_FILE_NAME="smarty-${SMARTY_VERSION}.tar.gz"
YII2_SMARTY_FILE_NAME="yii2-smarty-${YII2_SMARTY_VERSION}.tar.gz"
PARSEAPP_FILE_NAME="parse-app-${PARSEAPP_VERSION}.tar.gz"
HTMLPURIFIER_FILE_NAME="htmlpurifier-${HTMLPURIFIER_VERSION}.tar.gz"
LARAVEL_FILE_NAME="laravel-${LARAVEL_VERSION}.tar.gz"
LARAVEL_FRAMEWORK_FILE_NAME="framework-${LARAVEL_FRAMEWORK_VERSION}.tar.gz"
CKEDITOR_FILE_NAME="ckeditor_${CKEDITOR_VERSION}_full.tar.gz"
JQUERY_FILE_NAME="jquery-$JQUERY_VERSION.js"
JQUERY3_FILE_NAME="jquery-$JQUERY3_VERSION.js"
D3_FILE_NAME="d3-$D3_VERSION.zip"
CHARTJS_FILE_NAME="Chart.js-${CHARTJS_VERSION}.tar.gz"
FAMOUS_FILE_NAME="famous-${FAMOUS_VERSION}.tar.gz"
FAMOUS_ANGULAR_FILE_NAME="famous-angular-${FAMOUS_ANGULAR_VERSION}.tar.gz"
FAMOUS_FRAMEWORK_FILE_NAME="framework-${FAMOUS_FRAMEWORK_VERSION}.tar.gz"
SWFUPLOAD_FILE_NAME="SWFUpload v${SWFUPLOAD_VERSION} Core.zip"


#if [ "$OS_NAME" = 'darwin' ];then
KBPROTO_FILE_NAME="kbproto-${KBPROTO_VERSION}.tar.bz2"
INPUTPROTO_FILE_NAME="inputproto-${INPUTPROTO_VERSION}.tar.bz2"
XEXTPROTO_FILE_NAME="xextproto-${XEXTPROTO_VERSION}.tar.bz2"
XPROTO_FILE_NAME="xproto-${XPROTO_VERSION}.tar.bz2"
XTRANS_FILE_NAME="xtrans-${XTRANS_VERSION}.tar.bz2"
LIBXAU_FILE_NAME="libXau-${LIBXAU_VERSION}.tar.bz2"
LIBX11_FILE_NAME="libX11-${LIBX11_VERSION}.tar.bz2"
LIBPTHREAD_STUBS_FILE_NAME="libpthread-stubs-${LIBPTHREAD_STUBS_VERSION}.tar.bz2"
LIBXCB_FILE_NAME="libxcb-${LIBXCB_VERSION}.tar.bz2"
XCB_PROTO_FILE_NAME="xcb-proto-${XCB_PROTO_VERSION}.tar.bz2"
MACROS_FILE_NAME="util-macros-${MACROS_VERSION}.tar.bz2"
XF86BIGFONTPROTO_FILE_NAME="xf86bigfontproto-${XF86BIGFONTPROTO_VERSION}.tar.bz2"
#fi

GEOLITE2_CITY_MMDB_FILE_NAME="GeoLite2-City.mmdb.gz"
GEOLITE2_COUNTRY_MMDB_FILE_NAME="GeoLite2-Country.mmdb.gz"
LIBMAXMINDDB_FILE_NAME="libmaxminddb-${LIBMAXMINDDB_VERSION}.tar.gz"
MAXMIND_DB_READER_PHP_FILE_NAME="MaxMind-DB-Reader-php-${MAXMIND_DB_READER_PHP_VERSION}.tar.gz"
WEB_SERVICE_COMMON_PHP_FILE_NAME="web-service-common-php-${WEB_SERVICE_COMMON_PHP_VERSION}.tar.gz"
GEOIP2_PHP_FILE_NAME="GeoIP2-php-${GEOIP2_PHP_VERSION}.tar.gz"
GEOIPUPDATE_FILE_NAME="geoipupdate-${GEOIPUPDATE_VERSION}.tar.gz"
ELECTRON_FILE_NAME="electron-${ELECTRON_VERSION}.tar.gz"
#PHANTOMJS_FILE_NAME="phantomjs-${PHANTOMJS_VERSION}.tar.gz"
if [ "$OS_NAME" = "darwin" ];then
PHANTOMJS_FILE_NAME="phantomjs-${PHANTOMJS_VERSION}-macosx.zip"
else
PHANTOMJS_FILE_NAME="phantomjs-${PHANTOMJS_VERSION}-${OS_NAME}-${HOST_TYPE}.tar.bz2"
fi
DEHYDRATED_FILE_NAME="dehydrated-${DEHYDRATED_VERSION}.tar.gz"
NGINX_UPLOAD_PROGRESS_MODULE_FILE_NAME="nginx-upload-progress-module-${NGINX_UPLOAD_PROGRESS_MODULE_VERSION}.tar.gz"
NGINX_HTTP_GEOIP2_MODULE_FILE_NAME="ngx_http_geoip2_module-${NGINX_HTTP_GEOIP2_MODULE_VERSION}.tar.gz"
NGINX_PUSH_STREAM_MODULE_FILE_NAME="nginx-push-stream-module-${NGINX_PUSH_STREAM_MODULE_VERSION}.tar.gz"
NGINX_STICKY_MODULE_FILE_NAME="nginx-sticky-module-${NGINX_STICKY_MODULE_VERSION}.tar.gz"
NGINX_STICKY_MODULE_FILE_NAME="nginx-goodies-nginx-sticky-module-ng-c78b7dd79d0d.tar.gz"
NGINX_UPLOAD_MODULE_FILE_NAME="nginx-upload-module-${NGINX_UPLOAD_MODULE_VERSION}.tar.gz"
NGINX_INCUBATOR_PAGESPEED_FILE_NAME="incubator-pagespeed-ngx-${NGINX_INCUBATOR_PAGESPEED_VERSION}-stable.tar.gz"
PSOL_FILE_NAME="psol-${PSOL_VERSION}-x$( [ "$HOST_TYPE" = "x86_64" ] && echo "64" || echo "86" ).tar.gz"
# }}}

# }}}

# 是否尽量可能的使用系统自带lib
TRY_TO_USE_THE_SYSTEM=1

SBIN_DIR="$BASE_DIR/sbin"
BIN_DIR="$BASE_DIR/bin"
PHP_LIB_DIR=$PHP_BASE/lib
DATA_DIR=$BASE_DIR/data
LOG_DIR=$BASE_DIR/log

REDIS_CONFIG_DIR=$ETC_BASE/redis
GEARMAND_CONFIG_DIR=$ETC_BASE/gearmand
PHP_CONFIG_DIR=$ETC_BASE/php
NGINX_CONFIG_DIR=$ETC_BASE/nginx
STUNNEL_CONFIG_DIR=$ETC_BASE
RSYSLOG_CONFIG_DIR=$ETC_BASE/rsyslog
LOGROTATE_CONFIG_DIR=$ETC_BASE/logrotate
LOGROTATE_STATE_FILE=$DATA_DIR/logrotate/logrotate.status
MYSQL_CONFIG_DIR=$ETC_BASE/mysql
PHP_FPM_CONFIG_DIR=$ETC_BASE/php-fpm
APACHE_CONFIG_DIR=$ETC_BASE/apache
DEHYDRATED_CONFIG_DIR=$ETC_BASE/dehydrated
XAPIAN_OMEGA_CONFIG_DIR=$ETC_BASE/omega
SCWS_CONFIG_DIR=$ETC_BASE/scws

PHP_FPM_USER="nobody"
PHP_FPM_GROUP="nobody"

NGINX_LOG_DIR=$LOG_DIR/nginx
STUNNEL_LOG_DIR=$LOG_DIR/stunnel
NGINX_RUN_DIR=$BASE_DIR/run
#NGINX用户、所属组
NGINX_USER="nobody"
NGINX_GROUP="nobody"

HIDE_NGINX="1" ; # 隐藏nginx信息，以下面名字和版本号代替
NGINX_CUSTOMIZE_NAME="common"
NGINX_CUSTOMIZE_NAME_HUFFMAN='\x85\x21\xe9\xa4\xf5\x7f'
#NGINX_CUSTOMIZE_NAME_HUFFMAN=`./huffman --string ${NGINX_CUSTOMIZE_NAME}|awk '{print $NF;}'`
NGINX_CUSTOMIZE_VERSION="10.5.3"

RSYSLOG_LOG_DIR=$LOG_DIR/rsyslog

MYSQL_DATA_DIR=$DATA_DIR/mysql
MYSQL_RUN_DIR=$BASE_DIR/run/mysql
# mysql用户、组、初始化root密码
MYSQL_USER="mysql"
MYSQL_GROUP="mysql"
MYSQL_PASSWORD="chg365"

CLAMAV_CONF_DIR="$ETC_BASE/clamav"
CLAMAV_DATA_DIR="$DATA_DIR/clamav"
CLAMAV_USER="clamav"
CLAMAV_GROUP="clamav"

POSTGRESQL_CONFIG_DIR=$ETC_BASE/pgsql
POSTGRESQL_USER="postgres"
POSTGRESQL_GROUP="postgres"
POSTGRESQL_DATA_DIR="$DATA_DIR/pgsql"
POSTGRESQL_RUN_DIR="$BASE_DIR/run"

TMP_DATA_DIR=$DATA_DIR/tmp
WSDL_CACHE_DIR=$TMP_DATA_DIR/wsdl/
UPLOAD_TMP_DIR=$TMP_DATA_DIR/upload

php_ini=$PHP_CONFIG_DIR/php.ini
mysql_cnf=$MYSQL_CONFIG_DIR/my.cnf

PHP_INCLUDE_PATH="$BASE_DIR/conf:$BASE_DIR/lib/php:$BASE_DIR/inc";
#PHP_INCLUDE_PATH="${PHP_INCLUDE_PATH}:$PHP_BASE/lib/php";

APACHE_LOG_DIR=$LOG_DIR/apache
APACHE_RUN_DIR=$BASE_DIR/run/apache

GEOIP2_DATA_DIR=$DATA_DIR/geoip2

#https://github.com/squizlabs/PHP_CodeSniffer
#https://cs.symfony.com/
#https://github.com/FriendsOfPHP/PHP-CS-Fixer
#https://github.com/jupeter/clean-code-php
#http://code.z01.com/v4/docs/index.html
# https://github.com/ColorlibHQ/AdminLTE
# https://github.com/twbs/bootstrap/releases
