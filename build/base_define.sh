#!/bin/bash

project_name="chg base"
project_abbreviation="chg_base"

#HOSTTYPE=x86_64
#OSTYPE=linux-gnu
OS_NAME=`uname -s`;   # Linux
HOST_TYPE=`uname -i`; # x86_64

BASE_DIR=/usr/local/${project_abbreviation//_//}
COMPILE_BASE=$(dirname $BASE_DIR)/compile

CONTRIB_BASE=$BASE_DIR/contrib
OPT_BASE=$BASE_DIR/opt

# {{{ open source libray info
# {{{ open source libray install base dir
RE2C_BASE="$COMPILE_BASE"
PCRE_BASE=$CONTRIB_BASE
OPENSSL_BASE=$CONTRIB_BASE
ZLIB_BASE=$CONTRIB_BASE
CURL_BASE=$CONTRIB_BASE
ICU_BASE=$CONTRIB_BASE
LIBZIP_BASE=$CONTRIB_BASE
GETTEXT_BASE=$CONTRIB_BASE
LIBICONV_BASE=$CONTRIB_BASE
LIBXML2_BASE=$CONTRIB_BASE
JSON_BASE=$CONTRIB_BASE
LIBMCRYPT_BASE=$CONTRIB_BASE
PKGCONFIG_BASE=$CONTRIB_BASE
LIBGD_BASE=$CONTRIB_BASE
IMAGEMAGICK_BASE=$OPT_BASE/ImageMagick
JPEG_BASE=$CONTRIB_BASE
LIBXPM_BASE=$CONTRIB_BASE
IMAP_BASE=$CONTRIB_BASE
KERBEROS_BASE=$CONTRIB_BASE
GMP_BASE=$CONTRIB_BASE
LIBMEMCACHED_BASE=$CONTRIB_BASE
LIBEVENT_BASE=$CONTRIB_BASE
LIBQRENCODE_BASE=$CONTRIB_BASE
LIBSODIUM_BASE=$CONTRIB_BASE
ZEROMQ_BASE=$OPT_BASE/zeromq
MEMCACHED_BASE=$OPT_BASE/memcached
RABBITMQ_C_BASE=$CONTRIB_BASE
LIBXSLT_BASE=$CONTRIB_BASE
TIDY_BASE=$CONTRIB_BASE
SPHINX_BASE=$OPT_BASE/sphinx
SPHINX_CLIENT_BASE=$CONTRIB_BASE




LIBPNG_BASE=$CONTRIB_BASE
NASM_BASE=$CONTRIB_BASE
LIBJPEG_BASE=$CONTRIB_BASE
OPENJPEG_BASE=$CONTRIB_BASE
CAIRO_BASE=$CONTRIB_BASE
PIXMAN_BASE=$CONTRIB_BASE
EXPAT_BASE=$CONTRIB_BASE
FREETYPE_BASE=$CONTRIB_BASE
FONTCONFIG_BASE=$CONTRIB_BASE
POPPLER_BASE=$CONTRIB_BASE
PANGO_BASE=$CONTRIB_BASE
FONTFORGE_BASE=$CONTRIB_BASE
PDF2HTMLEX_BASE=$CONTRIB_BASE
#if [ "$OS_NAME" = 'Darwin' ];then
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
POSTGRESQL_BASE=$OPT_BASE/postgresql

APR_BASE=$CONTRIB_BASE
APR_UTIL_BASE=$CONTRIB_BASE


APACHE_BASE=$OPT_BASE/apache
NGINX_BASE=$OPT_BASE/nginx
MYSQL_BASE=$OPT_BASE/mysql
PHP_BASE=$OPT_BASE/php

ZEND_BASE=$BASE_DIR/inc/zend
SMARTY_BASE=$BASE_DIR/inc/smarty

CKEDITOR_BASE=$BASE_DIR/web/js/ckeditor
JQUERY_BASE=$BASE_DIR/web/js/
SWFUPLOAD_BASE=$BASE_DIR/web/js/swfupload


LIBMAXMINDDB_BASE=$CONTRIB_BASE
GEOIPUPDATE_BASE=$CONTRIB_BASE
ELECTRON_BASE=$CONTRIB_BASE
PHANTOMJS_BASE=$CONTRIB_BASE

# }}}
# {{{ open source libray version info
PKGCONFIG_VERSION="0.29" # http://pkgconfig.freedesktop.org/releases/
RE2C_VERSION="0.16" # http://re2c.org/about/about.html#version

PCRE_VERSION="8.39"
#PCRE_VERSION="10.20" # pcre2 编译apache时报错
OPENSSL_VERSION="1.0.2h"
ZLIB_VERSION="1.2.8" # www.zlib.net
CURL_VERSION="7.49.1"
ICU_VERSION="57.1" # http://site.icu-project.org/
LIBZIP_VERSION="1.1.3" # http://www.nih.at/libzip/index.html
GETTEXT_VERSION="0.19.7" # http://ftp.gnu.org/gnu/gettext/
LIBICONV_VERSION="1.14" # http://ftp.gnu.org/gnu/libiconv/
LIBXML2_VERSION="2.9.4" # ftp://xmlsoft.org/libxml2/
JSON_VERSION="0.12" # https://github.com/json-c/json-c/releases
LIBMCRYPT_VERSION="2.5.8" # http://sourceforge.net/projects/mcrypt/files/Libmcrypt/
LIBXPM_VERSION="3.5.11"
IMAP_VERSION="2007f"
KERBEROS_VERSION="1.14.2"
GMP_VERSION="6.1.1"
LIBMEMCACHED_VERSION="1.0.18" # 1.0.17 php memcached编译不过去  1.0.16
LIBEVENT_VERSION="2.0.22"
LIBQRENCODE_VERSION="3.4.4"
LIBXSLT_VERSION="1.1.29"
TIDY_VERSION="5.2.0"
SPHINX_VERSION="2.2.10"
PHP_SPHINX_VERSION="php7"

LIBGD_VERSION="2.1.1" # http://libgd.github.io/
IMAGEMAGICK_VERSION="7.0.2-3" # http://www.imagemagick.org/download/
JPEG_VERSION="9b" # 8d # http://www.ijg.org/files/
LIBPNG_VERSION="1.6.23"
NASM_VERSION="2.12.01"
LIBJPEG_VERSION="1.5.0"
OPENJPEG_VERSION="2.1" # 2.1.0
CAIRO_VERSION="1.14.6"
PIXMAN_VERSION="0.34.0"
EXPAT_VERSION="2.1.1"
FREETYPE_VERSION="2.6.3"
FONTCONFIG_VERSION="2.12.0"
POPPLER_VERSION="0.45.0"
PANGO_VERSION="1.40.1"
FONTFORGE_VERSION="20160404"
PDF2HTMLEX_VERSION="0.14.6" # https://github.com/coolwanglu/pdf2htmlEX
#if [ "$OS_NAME" = 'Darwin' ];then
LIBX11_VERSION="1.6.3"
XPROTO_VERSION="7.0.28"
MACROS_VERSION="1.19.0"
XCB_PROTO_VERSION="1.11"
LIBPTHREAD_STUBS_VERSION="0.3"
LIBXAU_VERSION="1.0.8"
LIBXCB_VERSION="1.11"
KBPROTO_VERSION="1.0.7"
INPUTPROTO_VERSION="2.3.1"
XEXTPROTO_VERSION="7.3.0"
XTRANS_VERSION="1.3.5"
XF86BIGFONTPROTO_VERSION="1.2.0"
#fi

LIBSODIUM_VERSION="1.0.10"
ZEROMQ_VERSION="4.1.5"
RABBITMQ_C_VERSION="0.8.0"
PHP_ZMQ_VERSION="php7" #1.1.3
PHP_LIBSODIUM_VERSION="1.0.0"

SQLITE_VERSION="3130000"
POSTGRESQL_VERSION="9.4.4"

APR_VERSION="1.5.2"
APR_UTIL_VERSION="1.5.4"

APACHE_VERSION="2.4.16"
MYSQL_VERSION="5.7.13"
BOOST_VERSION="1_59_0" # 1_61_0
NGINX_VERSION="1.8.0"
PHP_VERSION="7.0.7"

MEMCACHED_VERSION="1.4.29"
PHP_MEMCACHED_VERSION="php7"
EVENT_VERSION="2.1.0"
DIO_VERSION="0.0.7" # http://pecl.php.net/package/dio
PHP_LIBEVENT_VERSION="0.1.0" # http://pecl.php.net/package/libevent
APCU_VERSION="5.1.5"
APCU_BC_VERSION="1.0.3"
YAF_VERSION="3.0.3"
XDEBUG_VERSION="2.4.0"
RAPHF_VERSION="2.0.0"
PROPRO_VERSION="2.0.1"
PECL_HTTP_VERSION="3.0.1"
AMQP_VERSION="1.7.1"
MAILPARSE_VERSION="3.0.1"
PHP_REDIS_VERSION="3.0.0"
PHP_MONGODB_VERSION="1.1.8"
SOLR_VERSION="2.4.0"
IMAGICK_VERSION="3.4.3RC1" # http://pecl.php.net/package/imagick
PTHREADS_VERSION="3.1.6" # http://pecl.php.net/package/pthreads
SWOOLE_VERSION="1.8.7" # http://pecl.php.net/package/swoole
#QRENCODE_VERSION="0.0.3"
QRENCODE_VERSION="0.1.0"

ZEND_VERSION="2.4.9" # http://framework.zend.com/downloads/latest
SMARTY_VERSION="3.1.27" # www.smarty.net

CKEDITOR_VERSION="4.5.6" #  www.ckeditor.com
JQUERY_VERSION="1.11.3.min" # http://jquery.com/
#SWFUpload%20v2.2.0.1%20Core.zip
#SWFUpload_v250_beta_3_core.zip
SWFUPLOAD_VERSION="2.2.0.1"


LIBMAXMINDDB_VERSION="1.2.0"
MAXMIND_DB_READER_PHP_VERSION="1.1.0"
WEB_SERVICE_COMMON_PHP_VERSION="0.0.4"
GEOIP2_PHP_VERSION="2.4.1"
GEOIPUPDATE_VERSION="2.2.2"
ELECTRON_VERSION="1.4.1"
PHANTOMJS_VERSION=2.1.1

# }}}
# {{{ open source libray  file name
RE2C_FILE_NAME="re2c-$RE2C_VERSION.tar.gz"
OPENSSL_FILE_NAME="openssl-$OPENSSL_VERSION.tar.gz"
ICU_FILE_NAME="icu4c-${ICU_VERSION//./_}-src.tgz"
ZLIB_FILE_NAME="zlib-$ZLIB_VERSION.tar.gz"
LIBZIP_FILE_NAME="libzip-$LIBZIP_VERSION.tar.xz"
GETTEXT_FILE_NAME="gettext-$GETTEXT_VERSION.tar.xz"
LIBICONV_FILE_NAME="libiconv-$LIBICONV_VERSION.tar.gz"
LIBXML2_FILE_NAME="libxml2-$LIBXML2_VERSION.tar.gz"
JSON_FILE_NAME="json-c-$JSON_VERSION.tar.gz"
LIBMCRYPT_FILE_NAME="libmcrypt-$LIBMCRYPT_VERSION.tar.gz"
PKGCONFIG_FILE_NAME="pkg-config-$PKGCONFIG_VERSION.tar.gz"
SQLITE_FILE_NAME="sqlite-autoconf-$SQLITE_VERSION.tar.gz"
CURL_FILE_NAME="curl-$CURL_VERSION.tar.bz2"
MYSQL_FILE_NAME="mysql-$MYSQL_VERSION.tar.gz"
BOOST_FILE_NAME="boost_$BOOST_VERSION.tar.bz2"
PCRE_FILE_NAME="pcre-$PCRE_VERSION.tar.bz2"
NGINX_FILE_NAME="nginx-$NGINX_VERSION.tar.gz"
PHP_FILE_NAME="php-$PHP_VERSION.tar.xz"
PTHREADS_FILE_NAME="pthreads-$PTHREADS_VERSION.tgz"
SWOOLE_FILE_NAME="swoole-$SWOOLE_VERSION.tgz"
LIBPNG_FILE_NAME="libpng-$LIBPNG_VERSION.tar.xz"
PIXMAN_FILE_NAME="pixman-$PIXMAN_VERSION.tar.gz"
CAIRO_FILE_NAME="cairo-$CAIRO_VERSION.tar.xz"
NASM_FILE_NAME="nasm-$NASM_VERSION.tar.xz"
JPEG_FILE_NAME="jpegsrc.v$JPEG_VERSION.tar.gz"
LIBXSLT_FILE_NAME="libxslt-${LIBXSLT_VERSION}.tar.gz"
TIDY_FILE_NAME="tidy-html5-${TIDY_VERSION}.tar.gz"
SPHINX_FILE_NAME="sphinx-${SPHINX_VERSION}-release.tar.gz"
PHP_SPHINX_FILE_NAME="pecl-search_engine-sphinx-${PHP_SPHINX_VERSION}.tar.gz"
LIBJPEG_FILE_NAME="libjpeg-turbo-$LIBJPEG_VERSION.tar.gz"
OPENJPEG_FILE_NAME="openjpeg-version.$OPENJPEG_VERSION.tar.gz"
FREETYPE_FILE_NAME="freetype-${FREETYPE_VERSION}.tar.bz2"
EXPAT_FILE_NAME="expat-$EXPAT_VERSION.tar.bz2"
FONTCONFIG_FILE_NAME="fontconfig-${FONTCONFIG_VERSION}.tar.bz2"
POPPLER_FILE_NAME="poppler-$POPPLER_VERSION.tar.xz"
FONTFORGE_FILE_NAME="fontforge-${FONTFORGE_VERSION}.tar.gz"
PDF2HTMLEX_FILE_NAME="pdf2htmlEX-$PDF2HTMLEX_VERSION.tar.gz"
PANGO_FILE_NAME="pango-${PANGO_VERSION}.tar.xz"
LIBXPM_FILE_NAME="libXpm-$LIBXPM_VERSION.tar.bz2"
LIBGD_FILE_NAME="libgd-$LIBGD_VERSION.tar.gz"
IMAGEMAGICK_FILE_NAME="ImageMagick-$IMAGEMAGICK_VERSION.tar.xz"
GMP_FILE_NAME="gmp-$GMP_VERSION.tar.xz"
IMAP_FILE_NAME="imap-$IMAP_VERSION.tar.gz"
KERBEROS_FILE_NAME="krb5-$KERBEROS_VERSION.tar.gz"
LIBMEMCACHED_FILE_NAME="libmemcached-$LIBMEMCACHED_VERSION.tar.gz"
LIBEVENT_FILE_NAME="libevent-${LIBEVENT_VERSION}-stable.tar.gz"
LIBQRENCODE_FILE_NAME="qrencode-$LIBQRENCODE_VERSION.tar.bz2"
POSTGRESQL_FILE_NAME="postgresql-$POSTGRESQL_VERSION.tar.bz2"
APR_FILE_NAME="apr-$APR_VERSION.tar.gz"
APR_UTIL_FILE_NAME="apr-util-$APR_UTIL_VERSION.tar.gz"
APACHE_FILE_NAME="httpd-$APACHE_VERSION.tar.gz"
APCU_FILE_NAME="apcu-$APCU_VERSION.tgz"
APCU_BC_FILE_NAME="apcu_bc-$APCU_BC_VERSION.tgz"
YAF_FILE_NAME="yaf-$YAF_VERSION.tgz"
XDEBUG_FILE_NAME="xdebug-${XDEBUG_VERSION}.tgz"
RAPHF_FILE_NAME="raphf-${RAPHF_VERSION}.tgz"
PROPRO_FILE_NAME="propro-${PROPRO_VERSION}.tgz"
PECL_HTTP_FILE_NAME="pecl_http-${PECL_HTTP_VERSION}.tgz"
AMQP_FILE_NAME="amqp-${AMQP_VERSION}.tgz"
MAILPARSE_FILE_NAME="mailparse-${MAILPARSE_VERSION}.tgz"
PHP_REDIS_FILE_NAME="redis-${PHP_REDIS_VERSION}.tgz"
PHP_MONGODB_FILE_NAME="mongodb-${PHP_MONGODB_VERSION}.tgz"
SOLR_FILE_NAME="solr-${SOLR_VERSION}.tgz"
MEMCACHED_FILE_NAME="memcached-$MEMCACHED_VERSION.tar.gz"
PHP_MEMCACHED_FILE_NAME="php-memcached-${PHP_MEMCACHED_VERSION}.tar.gz"
EVENT_FILE_NAME="event-$EVENT_VERSION.tgz"
DIO_FILE_NAME="dio-$DIO_VERSION.tgz"
PHP_LIBEVENT_FILE_NAME="libevent-$PHP_LIBEVENT_VERSION.tgz"
IMAGICK_FILE_NAME="imagick-$IMAGICK_VERSION.tgz"
QRENCODE_FILE_NAME="qrencode-${QRENCODE_VERSION}.tar.gz"
LIBSODIUM_FILE_NAME="libsodium-${LIBSODIUM_VERSION}.tar.gz"
version=${ZEROMQ_VERSION%.*};
ZEROMQ_FILE_NAME="zeromq${version/./-}-${ZEROMQ_VERSION}.tar.gz"
RABBITMQ_C_FILE_NAME="rabbitmq-c-${RABBITMQ_C_VERSION}.tar.gz"
unset version;
PHP_ZMQ_FILE_NAME="php-zmq-${PHP_ZMQ_VERSION}.tar.gz"
PHP_LIBSODIUM_FILE_NAME="libsodium-${PHP_LIBSODIUM_VERSION}.tgz"
ZEND_FILE_NAME="ZendFramework-$ZEND_VERSION.tgz"
SMARTY_FILE_NAME="smarty-$SMARTY_VERSION.tar.gz"
CKEDITOR_FILE_NAME="ckeditor_${CKEDITOR_VERSION}_full.tar.gz"
JQUERY_FILE_NAME="jquery-$JQUERY_VERSION.js"
SWFUPLOAD_FILE_NAME="SWFUpload v$SWFUPLOAD_VERSION Core.zip"


#if [ "$OS_NAME" = 'Darwin' ];then
KBPROTO_FILE_NAME="kbproto-$KBPROTO_VERSION.tar.bz2"
INPUTPROTO_FILE_NAME="inputproto-$INPUTPROTO_VERSION.tar.bz2"
XEXTPROTO_FILE_NAME="xextproto-$XEXTPROTO_VERSION.tar.bz2"
XPROTO_FILE_NAME="xproto-$XPROTO_VERSION.tar.bz2"
XTRANS_FILE_NAME="xtrans-$XTRANS_VERSION.tar.bz2"
LIBXAU_FILE_NAME="libXau-$LIBXAU_VERSION.tar.bz2"
LIBX11_FILE_NAME="libX11-$LIBX11_VERSION.tar.bz2"
LIBPTHREAD_STUBS_FILE_NAME="libpthread-stubs-$LIBPTHREAD_STUBS_VERSION.tar.bz2"
LIBXCB_FILE_NAME="libxcb-$LIBXCB_VERSION.tar.bz2"
XCB_PROTO_FILE_NAME="xcb-proto-$XCB_PROTO_VERSION.tar.bz2"
MACROS_FILE_NAME="util-macros-$MACROS_VERSION.tar.bz2"
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
PHANTOMJS_FILE_NAME="phantomjs-${PHANTOMJS_VERSION}.tar.gz"
# }}}

# }}}

SBIN_DIR="$BASE_DIR/sbin"
PHP_LIB_DIR=$PHP_BASE/lib
DATA_DIR=$BASE_DIR/data
LOG_DIR=$BASE_DIR/log

PHP_CONFIG_DIR=$BASE_DIR/etc/php
NGINX_CONFIG_DIR=$BASE_DIR/etc/nginx
MYSQL_CONFIG_DIR=$BASE_DIR/etc/mysql
PHP_FPM_CONFIG_DIR=$BASE_DIR/etc/php-fpm
APACHE_CONFIG_DIR=$BASE_DIR/etc/apache

NGINX_LOG_DIR=$LOG_DIR/nginx


MYSQL_DATA_DIR=$DATA_DIR/mysql
MYSQL_RUN_DIR=$BASE_DIR/run/mysql

UPLOAD_TMP_DIR=$DATA_DIR/tmp/upload
WSDL_CACHE_DIR=$DATA_DIR/tmp/wsdl/

php_ini=$PHP_CONFIG_DIR/php.ini
mysql_cnf=$MYSQL_CONFIG_DIR/my.cnf

PHP_INCLUDE_PATH=".:$BASE_DIR/conf:$BASE_DIR/lib/php:$BASE_DIR/inc";

APACHE_LOG_DIR=$LOG_DIR/apache
APACHE_RUN_DIR=$BASE_DIR/run/apache

GEOIP2_ETC_DIR=$BASE_DIR/etc/geoip2
