#!/bin/bash
# https://github.com/cockroachdb/cockroach
# https://github.com/pingcap/tidb
# https://github.com/pingcap/docs-cn

project_name="chg base"
project_abbreviation="chg_base"

#HOSTTYPE=x86_64
#OSTYPE=linux-gnu
# MAC 不支持 declare -l
#declare -l OS_NAME
#declare -l HOST_TYPE
# getconf LONG_BIT # 32 64
OS_NAME=`uname -s|tr '[A-Z]' '[a-z]'`;   # Linux
HOST_TYPE=`uname -m|tr '[A-Z]' '[a-z]'`; # x86_64

BASE_DIR=/usr/local/${project_abbreviation//_//}
COMPILE_BASE=$(dirname $BASE_DIR)/compile

CONTRIB_BASE=$BASE_DIR/contrib
OPT_BASE=$BASE_DIR/opt
WEB_BASE=$BASE_DIR/web
JS_BASE=$WEB_BASE/public/js
CSS_BASE=$WEB_BASE/public/css

# {{{ open source libray info
# {{{ open source libray install base dir
READLINE_BASE=$CONTRIB_BASE
PATCHELF_BASE=$CONTRIB_BASE
TESSERACT_BASE="$OPT_BASE/tesseract"
RE2C_BASE="$COMPILE_BASE"
PCRE_BASE=$CONTRIB_BASE
OPENSSL_BASE=$CONTRIB_BASE
HIREDIS_BASE=$CONTRIB_BASE
ZLIB_BASE=$CONTRIB_BASE
CURL_BASE=$CONTRIB_BASE
NGHTTP2_BASE=$CONTRIB_BASE
ICU_BASE=$CONTRIB_BASE
LIBZIP_BASE=$CONTRIB_BASE
GETTEXT_BASE=$CONTRIB_BASE
LIBICONV_BASE=$CONTRIB_BASE
LIBXML2_BASE=$CONTRIB_BASE
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
KERBEROS_BASE=$CONTRIB_BASE
GMP_BASE=$CONTRIB_BASE
LIBMEMCACHED_BASE=$CONTRIB_BASE
LIBEVENT_BASE=$CONTRIB_BASE
LIBQRENCODE_BASE=$CONTRIB_BASE
LIBSODIUM_BASE=$CONTRIB_BASE
#ZEROMQ_BASE=$OPT_BASE/zeromq
ZEROMQ_BASE=$CONTRIB_BASE
LIBUNWIND_BASE=$CONTRIB_BASE
BOOST_BASE=$OPT_BASE/boost
MEMCACHED_BASE=$OPT_BASE/memcached
REDIS_BASE=$OPT_BASE/redis
GEARMAND_BASE=$OPT_BASE/gearmand
RABBITMQ_C_BASE=$CONTRIB_BASE
LIBXSLT_BASE=$CONTRIB_BASE
TIDY_BASE=$CONTRIB_BASE
SPHINX_BASE=$OPT_BASE/sphinx
SPHINX_CLIENT_BASE=$CONTRIB_BASE

SCWS_BASE=$CONTRIB_BASE
XAPIAN_CORE_SCWS_BASE=$CONTRIB_BASE
XUNSEARCH_BASE=$CONTRIB_BASE

XAPIAN_CORE_BASE="$OPT_BASE/xapian"
XAPIAN_OMEGA_BASE="$OPT_BASE/omega"
XAPIAN_BINDINGS_BASE="$OPT_BASE/bindings"

FRIBIDI_BASE=$CONTRIB_BASE
LIBPNG_BASE=$CONTRIB_BASE
NASM_BASE=$CONTRIB_BASE
LIBJPEG_BASE=$CONTRIB_BASE
OPENJPEG_BASE=$CONTRIB_BASE
CAIRO_BASE=$CONTRIB_BASE
PIXMAN_BASE=$CONTRIB_BASE
EXPAT_BASE=$CONTRIB_BASE
FREETYPE_BASE=$CONTRIB_BASE
GLIB_BASE=$CONTRIB_BASE
UTIL_LINUX_BASE=$CONTRIB_BASE
LIBFFI_BASE=$CONTRIB_BASE
HARFBUZZ_BASE=$CONTRIB_BASE
FONTCONFIG_BASE=$CONTRIB_BASE
POPPLER_BASE=$CONTRIB_BASE
PANGO_BASE=$CONTRIB_BASE
FONTFORGE_BASE=$CONTRIB_BASE
PDF2HTMLEX_BASE=$CONTRIB_BASE
#if [ "$OS_NAME" = 'darwin' ];then
LIBX11_BASE=$CONTRIB_BASE
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
RSYSLOG_BASE=$OPT_BASE/rsyslog
LOGROTATE_BASE="$CONTRIB_BASE"
LIBUUID_BASE="$CONTRIB_BASE"
LIBLOGGING_BASE=$CONTRIB_BASE
LIBGCRYPT_BASE=$CONTRIB_BASE
LIBGPG_ERROR_BASE=$CONTRIB_BASE
LIBESTR_BASE=$CONTRIB_BASE
MYSQL_BASE=$OPT_BASE/mysql
PHP_BASE=$OPT_BASE/php

GRPC_BASE="$CONTRIB_BASE"
CODEIGNITER_BASE=$BASE_DIR/inc/codeigniter
ZEND_BASE=$BASE_DIR/inc/zend
SMARTY_BASE=$BASE_DIR/inc/smarty
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
ELECTRON_BASE=$CONTRIB_BASE
PHANTOMJS_BASE=$CONTRIB_BASE
DEHYDRATED_BASE=$CONTRIB_BASE

# }}}
# {{{ open source libray version info
PKGCONFIG_VERSION="0.29.2"
RE2C_VERSION="1.0.3"
PATCHELF_VERSION="0.9"
TESSERACT_VERSION="3.05.01"
READLINE_VERSION="7.0"

PCRE_VERSION="8.41"
#PCRE_VERSION="10.30" # pcre2 编译apache时报错
OPENSSL_VERSION="1.1.0g" # 1.1.0g 编译不过去
HIREDIS_VERSION="0.13.3"
ZLIB_VERSION="1.2.11" # www.zlib.net
NGHTTP2_VERSION="1.30.0"
CURL_VERSION="7.58.0"
ICU_VERSION="58.2" # 59.1 gcc要4.4.8以上
if [ "$OS_NAME" != 'darwin' ];then
    gcc_minimum_version="4.4.7"
    gcc_version=`gcc --version 2>/dev/null|head -1|awk '{ print $3;}'`;
    gcc_new_version=`echo $gcc_version $gcc_minimum_version|tr " " "\n"|sort -rV|head -1`;
    if [ "$gcc_new_version" = "$gcc_minimum_version" ]; then
        ICU_VERSION="58.2"
    else
        ICU_VERSION="58.2" #升级到 59.1后 PHP7.1.8的intl扩展编译不过去 60.2 php 7.2.0编译不过去
    fi
fi
LIBZIP_VERSION="1.3.2" # 1.4.0 需要cmake 3.0.2
which cmake 1>/dev/null 2>/dev/null
if [ "$?" = "0" ];then
    cmake_version=`cmake --version 2>/dev/null|head -1|awk '{ print $NF;}'`;
    cmake_new_version=`echo $cmake_version 3.0.1|tr " " "\n"|sort -rV|head -1`;
    if [ "$cmake_new_version" != "3.0.1" ]; then
        LIBZIP_VERSION="1.4.0"
    fi
fi
GETTEXT_VERSION="0.19.8.1"
LIBICONV_VERSION="1.15"
LIBXML2_VERSION="2.9.7"
LIBWEBP_VERSION="0.6.1"
JSON_VERSION="0.13"
LIBFASTJSON_VERSION="0.99.8"
LIBMCRYPT_VERSION="2.5.8"
LIBWBXML_VERSION="0.11.6"
LIBXPM_VERSION="3.5.12"
LIBXEXT_VERSION="1.3.3"
IMAP_VERSION="2007f"
KERBEROS_VERSION="1.16"
GMP_VERSION="6.1.2"
LIBMEMCACHED_VERSION="1.0.18" # 1.0.17 php memcached编译不过去  1.0.16
LIBEVENT_VERSION="2.1.8"
LIBQRENCODE_VERSION="4.0.0"
LIBXSLT_VERSION="1.1.32"
TIDY_VERSION="5.6.0"
SPHINX_VERSION="2.2.11"
PHP_SPHINX_VERSION="php7"

SCWS_VERSION="1.2.3"
XAPIAN_CORE_SCWS_VERSION="1.2.22"
XUNSEARCH_VERSION="1.4.11"
XUNSEARCH_SDK_VERSION="1.4.11"
XUNSEARCH_FULL_VERSION="1.4.11"

XAPIAN_CORE_VERSION="1.4.5"
XAPIAN_OMEGA_VERSION="1.4.5"
XAPIAN_BINDINGS_VERSION="1.4.5"

FRIBIDI_VERSION="1.0.1"
LIBGD_VERSION="2.2.5"
IMAGEMAGICK_VERSION="7.0.7-23"
JPEG_VERSION="9c"
LIBPNG_VERSION="1.6.34"
NASM_VERSION="2.13.03"
LIBJPEG_VERSION="1.5.3"
OPENJPEG_VERSION="2.3.0" # 2.1.0
CAIRO_VERSION="1.14.6"
PIXMAN_VERSION="0.34.0"
EXPAT_VERSION="2.2.5"
FREETYPE_VERSION="2.9"
GLIB_VERSION="2.52.3" # 2.52.3没编译过去,报错 libblkid.so: undefined reference to `uuid_unparse@UUID_1.0'
UTIL_LINUX_VERSION="2.31.1"
LIBFFI_VERSION="3.2.1"
HARFBUZZ_VERSION="1.7.5"
FONTCONFIG_VERSION="2.12.93"
POPPLER_VERSION="0.57.0" #0.58.0 0.59.0 编译 pdf2htmlEX时报错 0.14.6;
which cmake 1>/dev/null 2>/dev/null
if [ "$?" = "0" ];then
    cmake_version=`cmake --version 2>/dev/null|head -1|awk '{ print $NF;}'`;
    cmake_new_version=`echo $cmake_version 3.0.999|tr " " "\n"|sort -rV|head -1`;
    #  0.60.1需要CMake 3.1.0
    if [ "$cmake_new_version" != "3.0.999" ]; then
        POPPLER_VERSION="0.62.0"
    fi
fi
PANGO_VERSION="1.41.1"
FONTFORGE_VERSION="20170731"
PDF2HTMLEX_VERSION="0.14.6"
#if [ "$OS_NAME" = 'darwin' ];then
LIBX11_VERSION="1.6.5"
XPROTO_VERSION="7.0.31"
MACROS_VERSION="1.19.1"
XCB_PROTO_VERSION="1.12"
LIBPTHREAD_STUBS_VERSION="0.4"
LIBXAU_VERSION="1.0.8"
LIBXCB_VERSION="1.12"
KBPROTO_VERSION="1.0.7"
INPUTPROTO_VERSION="2.3.2"
XEXTPROTO_VERSION="7.3.0"
XTRANS_VERSION="1.3.5"
XF86BIGFONTPROTO_VERSION="1.2.0"
#fi

LIBSODIUM_VERSION="1.0.16"
ZEROMQ_VERSION="4.2.3"
LIBUNWIND_VERSION="1.2.1"
RABBITMQ_C_VERSION="0.8.0"
PHP_ZMQ_VERSION="master" #1.1.3

SQLITE_VERSION="3220000"
POSTGRESQL_VERSION="10.2"
PGBOUNCER_VERSION="1.8.1"

APR_VERSION="1.6.3"
APR_UTIL_VERSION="1.6.1"

APACHE_VERSION="2.4.29"
MYSQL_VERSION="5.7.21"
BOOST_VERSION="1_65_0" # 1_61_0
NGINX_VERSION="1.12.2"
NODEJS_VERSION="9.5.0"
CALIBRE_VERSION="3.17.0"
GITBOOK_VERSION="3.2.2"
GITBOOK_CLI_VERSION="2.3.2"
RSYSLOG_VERSION="8.33.0"
LOGROTATE_VERSION="3.13.0"
LIBUUID_VERSION="1.0.3"
LIBLOGGING_VERSION="1.0.6"
LIBGCRYPT_VERSION="1.8.2"
LIBGPG_ERROR_VERSION="1.27"
LIBESTR_VERSION="0.1.10"
PHP_VERSION="7.2.2"
COMPOSER_VERSION="1.6.3"
BROWSCAP_INI_VERSION="6027"

if [ `echo "${PHP_VERSION}" "7.1.99"|tr " " "\n"|sort -rV|head -1` = "7.1.99" ]; then
    PHP_LIBSODIUM_VERSION="1.0.7"
else
    PHP_LIBSODIUM_VERSION="2.0.4"
fi
MEMCACHED_VERSION="1.5.5"
PHP_MEMCACHED_VERSION="3.0.4"
REDIS_VERSION="4.0.8"
GEARMAND_VERSION="1.1.18"
EVENT_VERSION="2.3.0"
DIO_VERSION="0.1.0"
PHP_LIBEVENT_VERSION="0.1.0"
APCU_VERSION="5.1.10"
APCU_BC_VERSION="1.0.4"
YAF_VERSION="3.0.6"
PHALCON_VERSION="3.3.1"
XDEBUG_VERSION="2.6.0"
RAPHF_VERSION="2.0.0"
PROPRO_VERSION="2.0.1"
PECL_HTTP_VERSION="3.1.1RC1"
AMQP_VERSION="1.9.3"
MAILPARSE_VERSION="3.0.2"
PHP_REDIS_VERSION="3.1.6"
PHP_GEARMAN_VERSION="2.0.3"
PHP_MONGODB_VERSION="1.4.0"
SOLR_VERSION="2.4.0"
IMAGICK_VERSION="3.4.3"
PTHREADS_VERSION="3.1.6"
ZIP_VERSION="1.15.2"
SWOOLE_VERSION="2.1.0"
PHP_PROTOBUF_VERSION="3.5.1.1"
PHP_GRPC_VERSION="1.9.0"
#QRENCODE_VERSION="0.0.3"
QRENCODE_VERSION="0.1.0"

ZEND_VERSION="2.4.9"
SMARTY_VERSION="3.1.31"
HTMLPURIFIER_VERSION="4.9.3"
LARAVEL_VERSION="5.6.0"
LARAVEL_FRAMEWORK_VERSION="5.6.3"

CKEDITOR_VERSION="4.8.0"
JQUERY_VERSION="1.12.4.min"
JQUERY3_VERSION="3.3.1.min"
D3_VERSION="5.0.0"
CHARTJS_VERSION="2.7.1"
FAMOUS_VERSION="0.3.5"
FAMOUS_FRAMEWORK_VERSION="0.13.1"
FAMOUS_ANGULAR_VERSION="0.5.2"
#SWFUpload%20v2.2.0.1%20Core.zip
#SWFUpload_v250_beta_3_core.zip
SWFUPLOAD_VERSION="2.2.0.1"


LIBMAXMINDDB_VERSION="1.3.2"
MAXMIND_DB_READER_PHP_VERSION="1.2.0"
WEB_SERVICE_COMMON_PHP_VERSION="0.5.0"
GEOIP2_PHP_VERSION="2.8.0"
GEOIPUPDATE_VERSION="2.5.0"
ELECTRON_VERSION="1.8.2"
if [ "$OS_NAME" = 'darwin' ];then
    PHANTOMJS_VERSION="2.1.1"
else
    PHANTOMJS_VERSION="1.9.7" # npm install gitbook-pdf -g 时用到这个版本，不能使用最新的版本
fi
DEHYDRATED_VERSION="0.5.0"

NGINX_UPLOAD_PROGRESS_MODULE_VERSION="0.9.2"
NGINX_HTTP_GEOIP2_MODULE_VERSION="2.0"
NGINX_PUSH_STREAM_MODULE_VERSION="0.5.4"
NGINX_STICKY_MODULE_VERSION="1.2.6"
NGINX_UPLOAD_MODULE_VERSION="2.2.0"

# }}}
# {{{ open source libray file name
READLINE_FILE_NAME="readline-${READLINE_VERSION}.tar.gz"
PATCHELF_FILE_NAME="patchelf-${PATCHELF_VERSION}.tar.gz"
TESSERACT_FILE_NAME="tesseract-${TESSERACT_VERSION}.tar.gz"
RE2C_FILE_NAME="re2c-${RE2C_VERSION}.tar.gz"
OPENSSL_FILE_NAME="openssl-${OPENSSL_VERSION}.tar.gz"
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
MYSQL_FILE_NAME="mysql-${MYSQL_VERSION}.tar.gz"
BOOST_FILE_NAME="boost_${BOOST_VERSION}.tar.bz2"
PCRE_FILE_NAME="pcre-${PCRE_VERSION}.tar.bz2"
NGINX_FILE_NAME="nginx-${NGINX_VERSION}.tar.gz"
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
COMPOSER_FILE_NAME="composer-${COMPOSER_VERSION}.tar.gz"
BROWSCAP_INI_FILE_NAME="browscap-${BROWSCAP_INI_VERSION}.ini"
PTHREADS_FILE_NAME="pthreads-${PTHREADS_VERSION}.tgz"
ZIP_FILE_NAME="zip-${ZIP_VERSION}.tgz"
SWOOLE_FILE_NAME="swoole-${SWOOLE_VERSION}.tgz"
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

FRIBIDI_FILE_NAME="fribidi-${FRIBIDI_VERSION}.tar.gz"
LIBJPEG_FILE_NAME="libjpeg-turbo-${LIBJPEG_VERSION}.tar.gz"
if [ `echo "${OPENJPEG_VERSION%.*}" "2.1"|tr " " "\n"|sort -rV|head -1` = "2.1" ]; then
    #2.1.0及以前文件名是 openjpeg-version.2.1.tar.gz
    OPENJPEG_FILE_NAME="openjpeg-${OPENJPEG_VERSION/%.0/}.tar.gz"
else
    OPENJPEG_FILE_NAME="openjpeg-${OPENJPEG_VERSION}.tar.gz"
fi
FREETYPE_FILE_NAME="freetype-${FREETYPE_VERSION}.tar.bz2"
GLIB_FILE_NAME="glib-${GLIB_VERSION}.tar.xz"
UTIL_LINUX_FILE_NAME="util-linux-${UTIL_LINUX_VERSION}.tar.xz"
LIBFFI_FILE_NAME="libffi-${LIBFFI_VERSION}.tar.gz"
HARFBUZZ_FILE_NAME="harfbuzz-${HARFBUZZ_VERSION}.tar.bz2"
EXPAT_FILE_NAME="expat-${EXPAT_VERSION}.tar.bz2"
FONTCONFIG_FILE_NAME="fontconfig-${FONTCONFIG_VERSION}.tar.bz2"
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
LIBQRENCODE_FILE_NAME="qrencode-${LIBQRENCODE_VERSION}.tar.bz2"
POSTGRESQL_FILE_NAME="postgresql-${POSTGRESQL_VERSION}.tar.bz2"
PGBOUNCER_FILE_NAME="pgbouncer-${PGBOUNCER_VERSION}.tar.gz"
APR_FILE_NAME="apr-${APR_VERSION}.tar.gz"
APR_UTIL_FILE_NAME="apr-util-${APR_UTIL_VERSION}.tar.gz"
APACHE_FILE_NAME="httpd-${APACHE_VERSION}.tar.gz"
APCU_FILE_NAME="apcu-${APCU_VERSION}.tgz"
APCU_BC_FILE_NAME="apcu_bc-${APCU_BC_VERSION}.tgz"
YAF_FILE_NAME="yaf-${YAF_VERSION}.tgz"
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
SOLR_FILE_NAME="solr-${SOLR_VERSION}.tgz"
MEMCACHED_FILE_NAME="memcached-${MEMCACHED_VERSION}.tar.gz"
PHP_MEMCACHED_FILE_NAME="memcached-${PHP_MEMCACHED_VERSION}.tgz"
REDIS_FILE_NAME="redis-${REDIS_VERSION}.tar.gz"
GEARMAND_FILE_NAME="gearmand-${GEARMAND_VERSION}.tar.gz"
EVENT_FILE_NAME="event-${EVENT_VERSION}.tgz"
DIO_FILE_NAME="dio-${DIO_VERSION}.tgz"
PHP_LIBEVENT_FILE_NAME="libevent-${PHP_LIBEVENT_VERSION}.tgz"
IMAGICK_FILE_NAME="imagick-${IMAGICK_VERSION}.tgz"
QRENCODE_FILE_NAME="qrencode-${QRENCODE_VERSION}.tar.gz"
LIBSODIUM_FILE_NAME="libsodium-${LIBSODIUM_VERSION}.tar.gz"
ZEROMQ_FILE_NAME="zeromq-${ZEROMQ_VERSION}.tar.gz"
LIBUNWIND_FILE_NAME="libunwind-${LIBUNWIND_VERSION}.tar.gz"
RABBITMQ_C_FILE_NAME="rabbitmq-c-${RABBITMQ_C_VERSION}.tar.gz"
PHP_ZMQ_FILE_NAME="php-zmq-${PHP_ZMQ_VERSION}.tar.gz"
PHP_LIBSODIUM_FILE_NAME="libsodium-${PHP_LIBSODIUM_VERSION}.tgz"
ZEND_FILE_NAME="ZendFramework-${ZEND_VERSION}.tgz"
SMARTY_FILE_NAME="smarty-${SMARTY_VERSION}.tar.gz"
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
# }}}

# }}}

SBIN_DIR="$BASE_DIR/sbin"
BIN_DIR="$BASE_DIR/bin"
PHP_LIB_DIR=$PHP_BASE/lib
DATA_DIR=$BASE_DIR/data
LOG_DIR=$BASE_DIR/log

REDIS_CONFIG_DIR=$BASE_DIR/etc/redis
GEARMAND_CONFIG_DIR=$BASE_DIR/etc/gearmand
PHP_CONFIG_DIR=$BASE_DIR/etc/php
NGINX_CONFIG_DIR=$BASE_DIR/etc/nginx
RSYSLOG_CONFIG_DIR=$BASE_DIR/etc/rsyslog
LOGROTATE_CONFIG_DIR=$BASE_DIR/etc/logrotate
LOGROTATE_STATE_FILE=$DATA_DIR/logrotate/logrotate.status
MYSQL_CONFIG_DIR=$BASE_DIR/etc/mysql
PHP_FPM_CONFIG_DIR=$BASE_DIR/etc/php-fpm
APACHE_CONFIG_DIR=$BASE_DIR/etc/apache
SSL_CONFIG_DIR=$BASE_DIR/etc/ssl
DEHYDRATED_CONFIG_DIR=$BASE_DIR/etc/dehydrated
XAPIAN_OMEGA_CONFIG_DIR=$BASE_DIR/etc/omega

PHP_FPM_USER="nobody"
PHP_FPM_GROUP="nobody"

NGINX_LOG_DIR=$LOG_DIR/nginx
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
MYSQL_USER="asdf"
MYSQL_GROUP="asdf"
MYSQL_PASSWORD="chg365"

POSTGRESQL_CONFIG_DIR=$BASE_DIR/etc/pgsql
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
