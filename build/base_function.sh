#!/bin/bash
# laravel框架关键技术解析

#IFS_old=$IFS
#IFS=$'\n'

function check_minimum_env_requirements()
{
# coreutils 7.0 sort
    :
#wget
# gcc 4.4.7
# make
# cmake
#pkg-config
# automake
# autoconfig
# sed
# cut
# tr
# awk
# grep
# tar
# xz
# bzip2
# bison
# yum install cyrus-sasl-devel # /usr/include/sasl/sasl.h
# yum install libestr
# yum install libtool-ltdl-devel
# yum install texinfo
}
function sed_quote()
{
# mac sed 不支持\< \> |
    local a=$1;
    # 替换转义符
    a=${a//\\/\\\\}
    # 替换.
    a=${a//./\\.}
    # 替换分隔符/
    a=${a//\//\\\/}
    echo $a;
#line=`sed -n "/^$(sed_quote $ext),/=" MIME_table.txt`
}
function sed_quote2()
{
    local a=$1;
    # 替换转义符
    a=${a//\\/\\\\}
    # 替换分隔符/
    a=${a//\//\\\/}
    echo $a;
}

# {{{ function check_bison_version()
function check_bison_version()
{
    which bison 1>/dev/null 2>/dev/null
    if [ "$?" != "0" ];then
        echo 'cannot find bison.' >&2
        return 1;
    fi
    local bison_version_vars=`bison --version 2> /dev/null | sed -n '1p' | cut -d ' ' -f 4 | sed -e 's/\./ /g' | tr -d a-z`
    local bison_version=""
    local bison_version_num=""
    if test -n "$bison_version_vars"; then
        set $bison_version_vars
        if [ -n "${3}" ];then
            bison_version="${1}.${2}.${3}"
            bison_version_num="`expr ${1} \* 10000 + ${2} \* 100 + ${3}`"
        else
            bison_version="${1}.${2}"
            bison_version_num="`expr ${1} \* 10000 + ${2} \* 100`"
        fi

        if [ $bison_version_num -lt 30000 ];then
            echo 'bion版本太低' >&2;
            return 1;
        else
            #echo "bison version: $bison_version";
            :
        fi
    else
        echo 'check bison version faild' >&2;
        return 1;
    fi
}
# }}}
# {{{ function get_ldflags()
get_ldflags()
{
    #mac下不支持 LDFLAGS -Wl, -R.../lib
    local i=1;
    local str=""
    for i in `echo "$@"|tr ' ' "\n" |sort -u`;
    do
    {
        if [ -d "${i}" ];then
            if [ "$OS_NAME" = "Darwin" ];then
                str="${str} -L${i}"
            elif [ "$OS_NAME" = "Linux" ];then
                str="${str} -L${i} -Wl,-R${i}"
            else
                str="${str} -L${i} -Wl,-R${i}"
                echo "未知系统[$OS_NAME]处理方式" >&2
            fi
        else
            echo "${i} 不是目录" >&2
        fi
    }
    done

    echo $str
}
# }}}
# {{{ function get_cppflags()
get_cppflags()
{
    local i=1;
    local str=""
    for i in `echo "$@"|tr ' ' "\n" |sort -u`;
    do
    {
        if [ -d "${i}" ];then
            str="${str} -I${i}"
        else
            echo "${i} 不是目录" >&2
        fi
    }
    done
    echo $str
}
# }}}
# function echo_build_start {{{
function echo_build_start()
{
    echo ""
    echo ""
    echo ""
    echo "****************************  ${@}  ****************************************"
    echo ""
    echo "===================================================================================="
    echo ""
}
# }}}
# function make_run() {{{ 判断configure是否成功，并执行make && make install
function make_run()
{
    if [ "${1%/*}" != "0" ];then
        echo "Install ${@#*/} failed." >&2;
        return 1;
    fi

    make && make install

    if [ $? -ne 0 ];then
        echo "Install ${@#*/} failed." >&2;
        return 1;
    fi
}
# }}}
# function is_finished_wget() {{{ 判断wget 下载文件是否成功
function is_finished_wget()
{
    if [ "${1%/*}" != "0" ];then
        echo "wget file ${@#*/} failed." >&2
        wget_fail=1;
        return 1;
    fi
}
# }}}
# function wget_lib() {{{ Download open source libray
function wget_lib()
{
    local FILE_NAME="$1"
    local FILE_URL="$2"

    if [ -z "$FILE_NAME" ];then
        is_finished_wget "1/Unknown file"
    fi

    if [ -f "$FILE_NAME" ];then
        return;
    fi

    if [ -z "$FILE_URL" ];then
        is_finished_wget "1/$FILE_NAME"
    fi

    wget --content-disposition --no-check-certificate $FILE_URL
    local wget_flag="$?"
    if [ "$wget_flag" = "8" ];then
        wget --no-check-certificate $FILE_URL
        local wget_flag="$?"
    fi
    is_finished_wget "$wget_flag/$FILE_NAME"

}
# }}}
# function wget_lib_boost() {{{
function wget_lib_boost()
{
    wget_lib $BOOST_FILE_NAME "https://sourceforge.net/projects/boost/files/boost/${BOOST_VERSION//_/.}/$BOOST_FILE_NAME/download"
}
# }}}
# {{{ function decompress()
function decompress()
{
    local FILE_NAME="$1"

    if [ -z "$FILE_NAME" ] || [ ! -f "$FILE_NAME" ] ;then
        return 1;
    fi

    if [ "${FILE_NAME%%.tar.xz}" != "$FILE_NAME" ];then
        tar Jxf $FILE_NAME
    elif [ "${FILE_NAME%%.tar.Z}" != "$FILE_NAME" ];then
        tar jxf $FILE_NAME
    elif [ "${FILE_NAME%%.tar.bz2}" != "$FILE_NAME" ];then
        tar jxf $FILE_NAME
    elif [ "${FILE_NAME%%.tar.gz}" != "$FILE_NAME" ];then
        tar zxf $FILE_NAME
    elif [ "${FILE_NAME%%.tgz}" != "$FILE_NAME" ];then
        tar zxf $FILE_NAME
    elif [ "${FILE_NAME%%.tar.lz}" != "$FILE_NAME" ];then
        tar --lzip -xf $FILE_NAME
    else
        return 1;
    fi
    # return $?;
}
# }}}
# {{{ function compile()
function compile()
{
    local NAME=$1
    local FILE_NAME=$2
    local FILE_DIR=$3
    local INSTALL_DIR=$4
    local COMMAND=$5
    local AFTER_MAKE_COMMAND=$6

    if [ -z "$NAME" ] || [ -z "$FILE_NAME" ] || [ -z "$FILE_DIR" ] || [ -z "$INSTALL_DIR" ] || [ -z "$COMMAND" ];then
        echo "Parameter error. " >&2
        # return 1;
        exit 1;
    fi

    local is_php_extension=0;
    if [ "${NAME/PHP_EXTENSION//}" != "$NAME" ] || [ "${COMMAND/PHP_EXTENSION//}" != "$COMMAND" ];then
        is_php_extension=1;
    fi

    echo_build_start $NAME
    decompress $FILE_NAME
    if [ "$?" != "0" ];then
        echo "decompress file error. FILE_NAME: $FILE_NAME" >&2
        # return 1;
        exit 1;
    fi

    cd $FILE_DIR
    if [ "$?" != "0" ];then
        #  return 1;
        exit 1;
    fi

    if [ $is_php_extension -eq 1 ];then
        $PHP_BASE/bin/phpize
        if [ "$?" != "0" ];then
            exit 1;
        fi
    fi

    echo "configure command: "
    #eval echo "\$$COMMAND"
    echo ${!COMMAND}
    echo ""
    ${!COMMAND}
    # eval "\$$COMMAND"

    make_run "$?/$NAME"
    if [ "$?" != "0" ];then
        exit 1;
    fi

    if [ -n "$AFTER_MAKE_COMMAND" ];then
        ${AFTER_MAKE_COMMAND}
        if [ "$?" != "0" ];then
            echo "command error. command: ${!AFTER_MAKE_COMMAND}" >&2
            exit 1;
        fi
    fi

    # cd ../
    cd -
    if [ "$?" != 0 ];then
        echo "cd dir error. command: cd -; pwd:`pwd`" >&2
        exit 1;
    fi
    local tmp_str=${FILE_DIR%%/*};
    if [ -z "$tmp_str" ] || [ "$tmp_str" = "." ] || [ "$tmp_str" = ".." ];then
        echo "rm  dir error. pwd:`pwd` file_dir: ${FILE_DIR} .  file package root dir: ${tmp_str}" >&2
        exit 1;
    fi
    # /bin/rm -rf $FILE_DIR
    /bin/rm -rf $tmp_str

    if [ "$?" != "0" ];then
        echo "rm dir error. command: /bin/rm -rf $FILE_DIR" >&2
        exit 1;
    fi

    if [ $is_php_extension -eq 1 ];then
        #写入php.ini
        write_extension_info_to_php_ini "$INSTALL_DIR"
        return;
    fi

    deal_pkg_config_path "$INSTALL_DIR"
    deal_ld_library_path "$INSTALL_DIR"
    deal_path "$INSTALL_DIR"

    if [ "$?" != 0 ];then
        exit 1;
    fi
}
# }}}}
# {{{ function function_exists() 检测函数是否定义
function function_exists()
{
    type -t "$1" 2>/dev/null|grep -q 'function'
    if [ "$?" != "0" ];then
        return 1;
    fi
    return 0;
}
# }}}
# function wget_base_library() {{{ Download open source libray
function wget_base_library()
{
    wget_fail=0;
    wget_lib $OPENSSL_FILE_NAME       "http://www.openssl.org/source/$OPENSSL_FILE_NAME"
    # http://download.icu-project.org/files/icu4c/$ICU_VERSION/$ICU_FILE_NAME
    wget_lib $ICU_FILE_NAME           "https://fossies.org/linux/misc/$ICU_FILE_NAME"
    # http://cdnetworks-kr-2.dl.sourceforge.net/project/libpng/zlib/$ZLIB_VERSION/$ZLIB_FILE_NAME
    wget_lib $ZLIB_FILE_NAME          "http://zlib.net/$ZLIB_FILE_NAME"
    wget_lib $LIBZIP_FILE_NAME        "http://www.nih.at/libzip/$LIBZIP_FILE_NAME"
    wget_lib $GETTEXT_FILE_NAME       "http://ftp.gnu.org/gnu/gettext/$GETTEXT_FILE_NAME"
    wget_lib $LIBICONV_FILE_NAME      "http://ftp.gnu.org/gnu/libiconv/$LIBICONV_FILE_NAME"
    wget_lib $LIBXML2_FILE_NAME       "ftp://xmlsoft.org/libxml2/$LIBXML2_FILE_NAME"
    wget_lib $JSON_FILE_NAME          "https://s3.amazonaws.com/json-c_releases/releases/$JSON_FILE_NAME"
    # http://sourceforge.net/projects/mcrypt/files/MCrypt/2.6.8/mcrypt-2.6.8.tar.gz/download
    wget_lib $LIBMCRYPT_FILE_NAME     "http://sourceforge.net/projects/mcrypt/files/Libmcrypt/$LIBMCRYPT_VERSION/$LIBMCRYPT_FILE_NAME/download"
    wget_lib $SQLITE_FILE_NAME        "http://www.sqlite.org/2017/$SQLITE_FILE_NAME"
    wget_lib $CURL_FILE_NAME          "http://curl.haxx.se/download/$CURL_FILE_NAME"
    # http://downloads.mysql.com/archives/mysql-${MYSQL_VERSION%.*}/$MYSQL_FILE_NAME
    # http://mysql.oss.eznetsols.org/Downloads/MySQL-${MYSQL_VERSION%.*}/$MYSQL_FILE_NAME
    wget_lib $MYSQL_FILE_NAME         "http://cdn.mysql.com/Downloads/MySQL-${MYSQL_VERSION%.*}/$MYSQL_FILE_NAME"
    wget_lib_boost
    wget_lib $PCRE_FILE_NAME          "http://sourceforge.net/projects/pcre/files/pcre/$PCRE_VERSION/$PCRE_FILE_NAME/download"
    wget_lib $NGINX_FILE_NAME         "http://nginx.org/download/$NGINX_FILE_NAME"
    wget_lib $PHP_FILE_NAME           "http://cn2.php.net/distributions/$PHP_FILE_NAME"
    wget_lib $PTHREADS_FILE_NAME      "http://pecl.php.net/get/$PTHREADS_FILE_NAME"
    wget_lib $SWOOLE_FILE_NAME        "http://pecl.php.net/get/$SWOOLE_FILE_NAME"
    wget_lib $LIBXSLT_FILE_NAME       "ftp://xmlsoft.org/libxslt/$LIBXSLT_FILE_NAME"
    wget_lib $TIDY_FILE_NAME          "https://github.com/htacg/tidy-html5/archive/${TIDY_FILE_NAME##*-}"
    wget_lib $SPHINX_FILE_NAME        "https://github.com/sphinxsearch/sphinx/archive/${SPHINX_FILE_NAME#*-}"
    wget_lib $PHP_SPHINX_FILE_NAME    "https://github.com/php/pecl-search_engine-sphinx/archive/${PHP_SPHINX_FILE_NAME##*-}"
    wget_lib $RSYSLOG_FILE_NAME       "http://www.rsyslog.com/files/download/rsyslog/${RSYSLOG_FILE_NAME}"
    #wget_lib $LIBFASTJSON_FILE_NAME   "https://github.com/rsyslog/libfastjson/archive/v${LIBFASTJSON_FILE_NAME##*-}"
    wget_lib $LIBFASTJSON_FILE_NAME   "http://download.rsyslog.com/libfastjson/${LIBFASTJSON_FILE_NAME}"
    #wget_lib $LIBLOGGING_FILE_NAME    "https://github.com/rsyslog/liblogging/archive/v${LIBLOGGING_FILE_NAME##*-}"
    wget_lib $LIBLOGGING_FILE_NAME    "http://download.rsyslog.com/liblogging/${LIBLOGGING_FILE_NAME}"
    wget_lib $LIBGCRYPT_FILE_NAME     "ftp://ftp.gnupg.org/gcrypt/libgcrypt/${LIBGCRYPT_FILE_NAME}"
    wget_lib $LIBGPG_ERROR_FILE_NAME  "ftp://ftp.gnupg.org/gcrypt/libgpg-error//${LIBGPG_ERROR_FILE_NAME}"
    wget_lib $LIBESTR_FILE_NAME       "http://libestr.adiscon.com/files/download/${LIBESTR_FILE_NAME}"

    # wget_lib $LIBPNG_FILE_NAME     "https://sourceforge.net/projects/libpng/files/libpng$(echo ${LIBPNG_VERSION%\.*}|sed 's/\.//g')/$LIBPNG_VERSION/$LIBPNG_FILE_NAME/download"
    local version=${LIBPNG_VERSION%.*};
    wget_lib $LIBPNG_FILE_NAME        "https://sourceforge.net/projects/libpng/files/libpng${version/./}/$LIBPNG_VERSION/$LIBPNG_FILE_NAME/download"

    #wget_lib $GLIB_FILE_NAME          "https://github.com/GNOME/glib/archive/${GLIB_FILE_NAME##*-}"
    wget_lib $GLIB_FILE_NAME          "http://ftp.acc.umu.se/pub/gnome/sources/glib/${GLIB_VERSION%.*}/${GLIB_FILE_NAME}"
    #wget_lib $LIBFFI_FILE_NAME        "https://github.com/libffi/libffi/archive/v${LIBFFI_FILE_NAME##*-}"
    wget_lib $LIBFFI_FILE_NAME        "ftp://sourceware.org/pub/libffi/${LIBFFI_FILE_NAME}"
    wget_lib $PIXMAN_FILE_NAME        "http://cairographics.org/releases/$PIXMAN_FILE_NAME"
    wget_lib $CAIRO_FILE_NAME         "http://cairographics.org/releases/$CAIRO_FILE_NAME"

    local version=${UTIL_LINUX_VERSION%.*};
    if [ "${version%.*}" = "${version}" ] ;then
        local version=${UTIL_LINUX_VERSION}
    fi
    wget_lib $UTIL_LINUX_FILE_NAME    "https://www.kernel.org/pub/linux/utils/util-linux/v${version}/${UTIL_LINUX_FILE_NAME}"

    wget_lib $NASM_FILE_NAME          "http://www.nasm.us/pub/nasm/releasebuilds/$NASM_VERSION/$NASM_FILE_NAME"
    wget_lib $JPEG_FILE_NAME          "http://www.ijg.org/files/$JPEG_FILE_NAME"
    wget_lib $LIBJPEG_FILE_NAME       "https://sourceforge.net/projects/libjpeg-turbo/files/$LIBJPEG_VERSION/$LIBJPEG_FILE_NAME/download"

    local tmp="v";
    is_new_version $OPENJPEG_VERSION "2.1.1"
    if [ "$?" = "1" ];then
        tmp="version.";
    fi
    wget_lib $OPENJPEG_FILE_NAME      "https://github.com/uclouvain/openjpeg/archive/${tmp}${OPENJPEG_FILE_NAME#*-}"
    wget_lib $FREETYPE_FILE_NAME      "https://sourceforge.net/projects/freetype/files/freetype${FREETYPE_VERSION%%.*}/$FREETYPE_VERSION/$FREETYPE_FILE_NAME/download"
    wget_lib $HARFBUZZ_FILE_NAME      "http://www.freedesktop.org/software/harfbuzz/release/$HARFBUZZ_FILE_NAME"
    wget_lib $EXPAT_FILE_NAME         "https://sourceforge.net/projects/expat/files/expat/$EXPAT_VERSION/$EXPAT_FILE_NAME/download"
    wget_lib $FONTCONFIG_FILE_NAME    "https://www.freedesktop.org/software/fontconfig/release/$FONTCONFIG_FILE_NAME"
    wget_lib $POPPLER_FILE_NAME       "https://poppler.freedesktop.org/$POPPLER_FILE_NAME"
    wget_lib $FONTFORGE_FILE_NAME     "https://github.com/fontforge/fontforge/archive/${FONTFORGE_FILE_NAME#*-}"
    wget_lib $PDF2HTMLEX_FILE_NAME    "https://github.com/coolwanglu/pdf2htmlEX/archive/v${PDF2HTMLEX_FILE_NAME#*-}"
    wget_lib $PANGO_FILE_NAME         "http://ftp.gnome.org/pub/GNOME/sources/pango/${PANGO_VERSION%.*}/$PANGO_FILE_NAME"
    wget_lib $LIBXPM_FILE_NAME        "https://www.x.org/releases/individual/lib/$LIBXPM_FILE_NAME"
    # wget_lib $LIBGD_FILE_NAME       "https://bitbucket.org/libgd/gd-libgd/downloads/$LIBGD_FILE_NAME"
    wget_lib $LIBGD_FILE_NAME         "http://fossies.org/linux/www/$LIBGD_FILE_NAME"
    #wget_lib $IMAGEMAGICK_FILE_NAME  "https://github.com/ImageMagick/ImageMagick/archive/${IMAGEMAGICK_FILE_NAME#*-}"
    wget_lib $IMAGEMAGICK_FILE_NAME  "http://www.imagemagick.org/download/releases/${IMAGEMAGICK_FILE_NAME}"
    wget_lib $GMP_FILE_NAME           "ftp://ftp.gmplib.org/pub/gmp/$GMP_FILE_NAME"
    wget_lib $IMAP_FILE_NAME          "ftp://ftp.cac.washington.edu/imap/$IMAP_FILE_NAME"
    wget_lib $KERBEROS_FILE_NAME      "http://web.mit.edu/kerberos/dist/krb5/${KERBEROS_VERSION%.*}/$KERBEROS_FILE_NAME"
    wget_lib $LIBMEMCACHED_FILE_NAME  "https://launchpad.net/libmemcached/${LIBMEMCACHED_VERSION%.*}/$LIBMEMCACHED_VERSION/+download/$LIBMEMCACHED_FILE_NAME"
    wget_lib $MEMCACHED_FILE_NAME     "http://memcached.org/files/${MEMCACHED_FILE_NAME}"
    wget_lib $REDIS_FILE_NAME         "http://download.redis.io/releases/${REDIS_FILE_NAME}"
    # wget_lib $LIBEVENT_FILE_NAME      "https://sourceforge.net/projects/levent/files//libevent-${LIBEVENT_VERSION%.*}/$LIBEVENT_FILE_NAME"
    # wget_lib $LIBEVENT_FILE_NAME      "https://sourceforge.net/projects/levent/files/release-${LIBEVENT_VERSION}-stable/$LIBEVENT_FILE_NAME/download"
    wget_lib $LIBEVENT_FILE_NAME      "https://github.com/libevent/libevent/archive/${LIBEVENT_FILE_NAME#*-}"
    wget_lib $GEARMAND_FILE_NAME       "https://github.com/gearman/gearmand/releases/download/${GEARMAND_VERSION}/${GEARMAND_FILE_NAME}"
    #wget_lib $GEARMAND_FILE_NAME      "https://github.com/gearman/gearmand/archive/${GEARMAND_FILE_NAME#*-}"
    wget_lib $PHP_GEARMAN_FILE_NAME   "https://github.com/wcgallego/pecl-gearman/archive/${PHP_GEARMAN_FILE_NAME}"
    wget_lib $LIBQRENCODE_FILE_NAME   "http://fukuchi.org/works/qrencode/$LIBQRENCODE_FILE_NAME"
    wget_lib $POSTGRESQL_FILE_NAME    "https://ftp.postgresql.org/pub/source/v$POSTGRESQL_VERSION/$POSTGRESQL_FILE_NAME"
    wget_lib $APR_FILE_NAME           "http://mirrors.cnnic.cn/apache//apr/$APR_FILE_NAME"
    wget_lib $APR_UTIL_FILE_NAME      "http://mirror.bit.edu.cn/apache//apr/$APR_UTIL_FILE_NAME"
    # http://mirror.bjtu.edu.cn/apache/httpd/$APACHE_FILE_NAME
    wget_lib $APACHE_FILE_NAME        "http://archive.apache.org/dist/httpd/$APACHE_FILE_NAME"
    wget_lib $APCU_FILE_NAME          "http://pecl.php.net/get/$APCU_FILE_NAME"
    wget_lib $APCU_BC_FILE_NAME       "http://pecl.php.net/get/$APCU_BC_FILE_NAME"
    wget_lib $YAF_FILE_NAME           "http://pecl.php.net/get/$YAF_FILE_NAME"
    wget_lib $PHALCON_FILE_NAME       "https://github.com/phalcon/cphalcon/archive/v${PHALCON_FILE_NAME#*-}"
    wget_lib $XDEBUG_FILE_NAME        "http://pecl.php.net/get/$XDEBUG_FILE_NAME"
    wget_lib $RAPHF_FILE_NAME         "http://pecl.php.net/get/$RAPHF_FILE_NAME"
    wget_lib $PROPRO_FILE_NAME        "http://pecl.php.net/get/$PROPRO_FILE_NAME"
    wget_lib $PECL_HTTP_FILE_NAME     "http://pecl.php.net/get/$PECL_HTTP_FILE_NAME"
    wget_lib $AMQP_FILE_NAME          "http://pecl.php.net/get/$AMQP_FILE_NAME"
    wget_lib $MAILPARSE_FILE_NAME     "http://pecl.php.net/get/$MAILPARSE_FILE_NAME"
    wget_lib $PHP_REDIS_FILE_NAME     "http://pecl.php.net/get/$PHP_REDIS_FILE_NAME"
    wget_lib $PHP_MONGODB_FILE_NAME   "http://pecl.php.net/get/$PHP_MONGODB_FILE_NAME"
    wget_lib $SOLR_FILE_NAME          "http://pecl.php.net/get/$SOLR_FILE_NAME"

    wget_lib $PHP_MEMCACHED_FILE_NAME "http://pecl.php.net/get/$PHP_MEMCACHED_FILE_NAME"
    wget_lib $EVENT_FILE_NAME         "http://pecl.php.net/get/$EVENT_FILE_NAME"
    wget_lib $DIO_FILE_NAME           "http://pecl.php.net/get/$DIO_FILE_NAME"
    wget_lib $PHP_LIBEVENT_FILE_NAME  "http://pecl.php.net/get/$PHP_LIBEVENT_FILE_NAME"
    wget_lib $IMAGICK_FILE_NAME       "http://pecl.php.net/get/$IMAGICK_FILE_NAME"
    wget_lib $PHP_LIBSODIUM_FILE_NAME "http://pecl.php.net/get/$PHP_LIBSODIUM_FILE_NAME"
    wget_lib $QRENCODE_FILE_NAME      "https://github.com/chg365/qrencode/archive/${QRENCODE_FILE_NAME#*-}"
    wget_lib $COMPOSER_FILE_NAME      "https://github.com/composer/composer/archive/${COMPOSER_FILE_NAME#*-}"

    wget_lib $LARAVEL_FILE_NAME       "https://github.com/laravel/laravel/archive/v${LARAVEL_FILE_NAME#*-}"
    wget_lib $HIREDIS_FILE_NAME       "https://github.com/redis/hiredis/archive/v${HIREDIS_FILE_NAME#*-}"
    wget_lib $LARAVEL_FRAMEWORK_FILE_NAME "https://github.com/laravel/framework/archive/v${LARAVEL_FRAMEWORK_FILE_NAME#*-}"
    wget_lib $ZEND_FILE_NAME          "https://packages.zendframework.com/releases/ZendFramework-$ZEND_VERSION/$ZEND_FILE_NAME"
    wget_lib $SMARTY_FILE_NAME        "https://github.com/smarty-php/smarty/archive/v${SMARTY_FILE_NAME#*-}"
    wget_lib $CKEDITOR_FILE_NAME      "http://download.cksource.com/CKEditor/CKEditor/CKEditor%20$CKEDITOR_VERSION/$CKEDITOR_FILE_NAME"
    wget_lib $JQUERY_FILE_NAME        "http://code.jquery.com/$JQUERY_FILE_NAME"
    wget_lib $RABBITMQ_C_FILE_NAME    "https://github.com/alanxz/rabbitmq-c/archive/v${RABBITMQ_C_FILE_NAME##*-}"

    wget_lib $ZEROMQ_FILE_NAME        "https://github.com/zeromq/libzmq/releases/download/v${ZEROMQ_VERSION}/$ZEROMQ_FILE_NAME"
    wget_lib $LIBUNWIND_FILE_NAME     "http://download.savannah.gnu.org/releases/libunwind/$LIBUNWIND_FILE_NAME"
    wget_lib $LIBSODIUM_FILE_NAME     "https://download.libsodium.org/libsodium/releases/$LIBSODIUM_FILE_NAME"
    wget_lib $PHP_ZMQ_FILE_NAME       "https://github.com/mkoppanen/php-zmq/archive/${PHP_ZMQ_FILE_NAME##*-}"
    # wget_lib $SWFUPLOAD_FILE_NAME    "http://swfupload.googlecode.com/files/SWFUpload%20v$SWFUPLOAD_VERSION%20Core.zip"
    wget_lib $GEOLITE2_CITY_MMDB_FILE_NAME    "http://geolite.maxmind.com/download/geoip/database/$GEOLITE2_CITY_MMDB_FILE_NAME"
    wget_lib $GEOLITE2_COUNTRY_MMDB_FILE_NAME "http://geolite.maxmind.com/download/geoip/database/$GEOLITE2_COUNTRY_MMDB_FILE_NAME"
    wget_lib $LIBMAXMINDDB_FILE_NAME  "https://github.com/maxmind/libmaxminddb/releases/download/${LIBMAXMINDDB_VERSION}/${LIBMAXMINDDB_FILE_NAME}"
    wget_lib $MAXMIND_DB_READER_PHP_FILE_NAME "https://github.com/maxmind/MaxMind-DB-Reader-php/archive/v${MAXMIND_DB_READER_PHP_FILE_NAME##*-}"
    wget_lib $WEB_SERVICE_COMMON_PHP_FILE_NAME "https://github.com/maxmind/web-service-common-php/archive/v${WEB_SERVICE_COMMON_PHP_FILE_NAME##*-}"
    wget_lib $PKGCONFIG_FILE_NAME     "https://pkg-config.freedesktop.org/releases/$PKGCONFIG_FILE_NAME"
    wget_lib $GEOIP2_PHP_FILE_NAME    "https://github.com/maxmind/GeoIP2-php/archive/v${GEOIP2_PHP_FILE_NAME##*-}"
    wget_lib $GEOIPUPDATE_FILE_NAME   "https://github.com/maxmind/geoipupdate/releases/download/v${GEOIPUPDATE_VERSION}/$GEOIPUPDATE_FILE_NAME"
    wget_lib $ELECTRON_FILE_NAME      "https://github.com/electron/electron/archive/v${ELECTRON_FILE_NAME#*-}"

    wget_lib $PHANTOMJS_FILE_NAME     "https://github.com/ariya/phantomjs/archive/${PHANTOMJS_FILE_NAME#*-}"

    wget_lib $FAMOUS_FILE_NAME "https://github.com/Famous/famous/archive/${FAMOUS_FILE_NAME##*-}"
    wget_lib $FAMOUS_FRAMEWORK_FILE_NAME "https://github.com/Famous/framework/archive/v${FAMOUS_FRAMEWORK_FILE_NAME##*-}"
    wget_lib $FAMOUS_ANGULAR_FILE_NAME "https://github.com/Famous/famous-angular/archive/${FAMOUS_ANGULAR_FILE_NAME##*-}"

#    if [ "$OS_NAME" = 'Darwin' ];then

        wget_lib $KBPROTO_FILE_NAME          "https://www.x.org/archive/individual/proto/$KBPROTO_FILE_NAME"
        wget_lib $INPUTPROTO_FILE_NAME       "https://www.x.org/archive/individual/proto/$INPUTPROTO_FILE_NAME"
        wget_lib $XEXTPROTO_FILE_NAME        "https://www.x.org/archive/individual/proto/$XEXTPROTO_FILE_NAME"
        wget_lib $XPROTO_FILE_NAME           "https://www.x.org/archive/individual/proto/$XPROTO_FILE_NAME"
        wget_lib $XTRANS_FILE_NAME           "https://www.x.org/archive/individual/lib/$XTRANS_FILE_NAME"
        wget_lib $LIBXAU_FILE_NAME           "https://www.x.org/archive/individual/lib/$LIBXAU_FILE_NAME"
        wget_lib $LIBX11_FILE_NAME           "https://www.x.org/archive/individual/lib/$LIBX11_FILE_NAME"
        wget_lib $LIBPTHREAD_STUBS_FILE_NAME "https://www.x.org/archive/individual/xcb/$LIBPTHREAD_STUBS_FILE_NAME"
        wget_lib $LIBXCB_FILE_NAME           "https://www.x.org/archive/individual/xcb/$LIBXCB_FILE_NAME"
        wget_lib $XCB_PROTO_FILE_NAME        "https://www.x.org/archive/individual/xcb/$XCB_PROTO_FILE_NAME"
        wget_lib $MACROS_FILE_NAME           "https://www.x.org/archive/individual/util/$MACROS_FILE_NAME"
        wget_lib $XF86BIGFONTPROTO_FILE_NAME "https://www.x.org/archive/individual/proto/${XF86BIGFONTPROTO_FILE_NAME}"

#    fi

    if [ "$wget_fail" = "1" ];then
        exit 1;
    fi
}
# }}}
# function wget_env_library() {{{ Download open source libray
function wget_env_library()
{
    wget_fail="0"
    # http://ftp.gnu.org/gnu/wget/wget-1.18.tar.xz
    # http://ftp.gnu.org/gnu/tar/tar-1.29.tar.xz
    # http://ftp.gnu.org/gnu/sed/sed-4.2.2.tar.bz2
    # http://ftp.gnu.org/gnu/gzip/gzip-1.8.tar.xz


    wget_lib $BINUTILS_FILE_NAME "http://ftp.gnu.org/gnu/binutils/$BINUTILS_FILE_NAME"
    # https://github.com/antlr/antlr4/archive/4.5.3.tar.gz
    wget_lib $ISL_FILE_NAME "ftp://gcc.gnu.org/pub/gcc/infrastructure/$ISL_FILE_NAME"
    wget_lib $GMP_FILE_NAME "http://ftp.gnu.org/gnu/gmp/$GMP_FILE_NAME"
    wget_lib $MPC_FILE_NAME "http://ftp.gnu.org/gnu/mpc/$MPC_FILE_NAME"
    wget_lib $MPFR_FILE_NAME "http://ftp.gnu.org/gnu/mpfr/$MPFR_FILE_NAME"
    wget_lib $GCC_FILE_NAME "http://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/$GCC_FILE_NAME"
    wget_lib $BISON_FILE_NAME "http://ftp.gnu.org/gnu/bison/$BISON_FILE_NAME"
    wget_lib $AUTOMAKE_FILE_NAME "http://ftp.gnu.org/gnu/automake/$AUTOMAKE_FILE_NAME"
    wget_lib $AUTOCONF_FILE_NAME "http://ftp.gnu.org/gnu/autoconf/$AUTOCONF_FILE_NAME"
    wget_lib $LIBTOOL_FILE_NAME "http://ftp.gnu.org/gnu/libtool/$LIBTOOL_FILE_NAME"
    wget_lib $M4_FILE_NAME "http://ftp.gnu.org/gnu/m4/$M4_FILE_NAME"
    wget_lib $GLIBC_FILE_NAME "http://ftp.gnu.org/gnu/glibc/$GLIBC_FILE_NAME"
    wget_lib $MAKE_FILE_NAME "http://ftp.gnu.org/gnu/make/$MAKE_FILE_NAME"
    wget_lib $PATCH_FILE_NAME "http://ftp.gnu.org/gnu/patch/$PATCH_FILE_NAME"
    wget_lib $READLINE_FILE_NAME "http://ftp.gnu.org/gnu/readline/$READLINE_FILE_NAME"

    wget_lib $RE2C_FILE_NAME "https://sourceforge.net/projects/re2c/files/$RE2C_VERSION/$RE2C_FILE_NAME/download"
    wget_lib $FLEX_FILE_NAME "https://sourceforge.net/projects/flex/files/$FLEX_FILE_NAME/download"
    wget_lib $PKGCONFIG_FILE_NAME "https://pkg-config.freedesktop.org/releases/$PKGCONFIG_FILE_NAME"
    # wget_lib $PKGCONFIG_FILE_NAME "http://pkgconfig.freedesktop.org/releases/$PKGCONFIG_FILE_NAME"

    wget_lib $PPL_FILE_NAME "http://bugseng.com/products/ppl/download/ftp/releases/${PPL_VERSION}/$PPL_FILE_NAME"
    wget_lib $CLOOG_FILE_NAME "http://www.bastoul.net/cloog/pages/download/$CLOOG_FILE_NAME"
    # http://www.bastoul.net/cloog/pages/download/piplib-1.4.0.tar.gz


    wget_lib $PYTHON_FILE_NAME "https://www.python.org/ftp/python/$PYTHON_VERSION/$PYTHON_FILE_NAME"

    wget_lib $CMAKE_FILE_NAME "https://cmake.org/files/v${CMAKE_VERSION%.*}/$CMAKE_FILE_NAME"

    if [ "$wget_fail" = "1" ];then
        exit 1;
    fi
}
# }}}
# {{{ nginx mysql php 配置修改
# function write_extension_info_to_php_ini() {{{ 把单独编译的php扩展写入php.ini
function write_extension_info_to_php_ini()
{
    local line=`sed -n '/^;\{0,1\}extension=/h;${x;p;}' $php_ini`;
    sed -i.bak.$$ "/^$line\$/{a\\
extension=$1
;}" $php_ini

    #sed -i "/^;\{0,1\}extension=/h;\${x;a\\
    #    extension=$1
    #    ;x;}" $php_ini
}
# }}}
# function write_zend_extension_info_to_php_ini() {{{ 把单独编译的php扩展写入php.ini
function write_zend_extension_info_to_php_ini()
{
    local line=`sed -n '/^;\{0,1\}extension=/h;${x;p;}' $php_ini`;
    sed -i.bak "/^$line\$/{a\\
zend_extension=$1
;}" $php_ini

    #sed -i "/^;\{0,1\}zend_extension=/h;\${x;a\\
    #    extension=$1
    #    ;x;}" $php_ini
}
# }}}
# function change_php_ini() {{{
function change_php_ini()
{
    local num=`sed -n "/$1/=" $php_ini`;
    if [ "$num" = "" ];then
        echo "从${php_ini}文件中查找pattern($1)失败";
        exit 1;
    fi

    #num=`grep -n "$1" $php_ini|awk -F: '{print $1; }'`;
    #if [ $? != "0" ];then
        #echo '查找失败';
        #exit;
    #fi

    sed -i.bak.$$ "${num[0]}s/$1/$2/" $php_ini
    if [ $? != "0" ];then
        echo "在${php_ini}文件中执行替换失败. pattern($1) ($2)";
        exit 1;
    fi
}
# }}}
# function init_php_ini() {{{
function init_php_ini()
{
    # expose_php = Off
    # pattern='^expose_php \{0,\}= \{0,\}\(on\|On\|ON\) \{0,\}$'; # mac sed不支持 |
    local pattern='^expose_php \{0,\}= \{0,\}\([oO][nN]\) \{0,\}$';
    change_php_ini "$pattern" "expose_php = Off"
    # memory_limit
    local pattern='^memory_limit \{0,\}= \{0,\}[0-9]\{1,3\}M \{0,\}$';
    change_php_ini "$pattern" "memory_limit = 2048M"
    # post_max_size
    local pattern='^post_max_size \{0,\}= \{0,\}[0-9]\{1,2\}M \{0,\}$';
    change_php_ini "$pattern" "post_max_size = 2048M"
    # ;include_path = ".:/php/includes"
    local pattern='^; \{0,\}include_path \{0,\}= \{0,\}\"\.:\/php\/includes\"$';
    change_php_ini "$pattern" "include_path = \\\"$( echo $PHP_INCLUDE_PATH|sed 's/\//\\\//g' )\\\""
    # extension_dir
    # local pattern='^; \{0,\}extension_dir \{0,\}= \{0,\}\".\/\"$';
    # change_php_ini "$pattern" "extension_dir = \\\"$( echo $PHP_EXTENSION_DIR|sed 's/\//\\\//g' )\\\""
    # ;upload_tmp_dir =
    local pattern='^; \{0,\}upload_tmp_dir \{0,\}=.\{0,\}$';
    change_php_ini "$pattern" "upload_tmp_dir = \\\"$( echo $UPLOAD_TMP_DIR|sed 's/\//\\\//g' )\\\""
    # upload_max_filesize
    local pattern='^upload_max_filesize \{0,\}= \{0,\}[0-9]\{1,2\}M \{0,\}$';
    change_php_ini "$pattern" "upload_max_filesize = 2048M"
    # ;date.timezone =
    local pattern='^; \{0,\}date.timezone \{0,\}=.\{0,\}$';
    change_php_ini "$pattern" "date.timezone = \\\"Asia\/Shanghai\\\""

    # session.cookie_httponly =
    local pattern='^session.cookie_httponly \{0,\}= \{0,\}.\{0,\}$';
    change_php_ini "$pattern" "session.cookie_httponly = 1"

    # soap.wsdl_cache_dir="/tmp"
    mkdir -p $WSDL_CACHE_DIR
    local pattern='^soap\.wsdl_cache_dir \{0,\}= \{0,\}\"\/tmp\"$';
    change_php_ini "$pattern" "soap.wsdl_cache_dir= \\\"$( echo $WSDL_CACHE_DIR|sed 's/\//\\\//g' )\\\""

    #[APCU]
    #apc.rfc1867 = 1
    #apc.rfc1867_freq = 2
    #apc.cache_by_default=Off
    #; apc.filter=""
    #; apc.rfc1867_name = "APC_UPLOAD_PROGRESS"
    #; apc.rfc1867_prefix = "upload_"
    #; apc.rfc1867_freq = 0
}
# }}}
# function change_php_fpm_ini() {{{
function change_php_fpm_ini()
{
    local num=`sed -n "/$1/=" $3`;
    if [ "$num" = "" ];then
        echo "从${3}文件中查找pattern($1)失败";
        exit 1;
    fi

    sed -i.bak.$$ "${num[0]}s/$1/${2//\//\\/}/" $3
    if [ $? != "0" ];then
        echo "在${3}文件中执行替换失败. pattern($1) ($2)";
        exit 1;
    fi
}
# }}}
# function init_php_fpm_ini() {{{
function init_php_fpm_ini()
{
    # pid
    local pattern='^;pid \{0,\}= \{0,\}.\{1,\}$';
    change_php_fpm_ini "$pattern" "pid = ${BASE_DIR}/run/php-fpm.pid" "$PHP_FPM_CONFIG_DIR/php-fpm.conf"

    # error_log
    local pattern='^;error_log \{0,\}= \{0,\}.\{1,\}$';
    change_php_fpm_ini "$pattern" "error_log = ${LOG_DIR}/php-fpm/php-fpm.log" "$PHP_FPM_CONFIG_DIR/php-fpm.conf"

    # log_level
    local pattern='^;\(log_level \{0,\}= \{0,\}.\{1,\}\)$';
    change_php_fpm_ini "$pattern" "\\1" "$PHP_FPM_CONFIG_DIR/php-fpm.conf"

    # access.log
    local pattern='^;access.log \{0,\}= \{0,\}.\{1,\}$';
    change_php_fpm_ini "$pattern" "access.log = $LOG_DIR/php-fpm/\$pool.access.log" "$PHP_FPM_CONFIG_DIR/php-fpm.d/www.conf"

    # slowlog
    local pattern='^;slowlog \{0,\}= \{0,\}.\{1,\}$';
    change_php_fpm_ini "$pattern" "slowlog = $LOG_DIR/php-fpm/\$pool.log.slow" "$PHP_FPM_CONFIG_DIR/php-fpm.d/www.conf"

    # listen
    local pattern='^\(listen = [0-9.]\{1,\}:\)[0-9]\{1,\}$';
    change_php_fpm_ini "$pattern" "\19040" "$PHP_FPM_CONFIG_DIR/php-fpm.d/www.conf"
}
# }}}
# function init_mysql_cnf() {{{
function init_mysql_cnf()
{
    sed -i.bak.$$ "s/\<MYSQL_BASE_DIR\>/$( echo $MYSQL_BASE|sed 's/\//\\\//g' )/" $mysql_cnf;
    sed -i.bak.$$ "s/\<MYSQL_RUN_DIR\>/$( echo $MYSQL_RUN_DIR|sed 's/\//\\\//g' )/" $mysql_cnf;
    sed -i.bak.$$ "s/\<MYSQL_CONFIG_DIR\>/$( echo $MYSQL_CONFIG_DIR|sed 's/\//\\\//g' )/" $mysql_cnf;
    sed -i.bak.$$ "s/\<MYSQL_DATA_DIR\>/$( echo $MYSQL_DATA_DIR|sed 's/\//\\\//g' )/" $mysql_cnf;
}
# }}}
# function init_nginx_conf() {{{
function init_nginx_conf()
{
    mkdir -p $NGINX_CONFIG_DIR
    cp $curr_dir/nginx/nginx.conf $NGINX_CONFIG_DIR/nginx.conf


    sed -i.bak.$$ "s/WEB_ROOT_DIR/$(sed_quote2 $BASE_DIR/web)/g" $NGINX_CONFIG_DIR/nginx.conf
    sed -i.bak.$$ "s/GEOIP2_DATA_DIR/$(sed_quote2 $GEOIP2_DATA_DIR)/g" $NGINX_CONFIG_DIR/nginx.conf
    sed -i.bak.$$ "s/LOG_DIR/$(sed_quote2 $LOG_DIR)/g" $NGINX_CONFIG_DIR/nginx.conf
    sed -i.bak.$$ "s/RUN_DIR/$(sed_quote2 $BASE_DIR/run)/g" $NGINX_CONFIG_DIR/nginx.conf
    sed -i.bak.$$ "s/PROJECT_NAME/$(sed_quote2 $project_abbreviation)/g" $NGINX_CONFIG_DIR/nginx.conf
#    nobody

    # fastcgi_param  SERVER_SOFTWARE
    sed -i.bak.$$ "s/^\(fastcgi_param \{1,\}SERVER_SOFTWARE \{1,\}\)nginx\/\$nginx_version;$/\1${project_name%% *}\/1.0;/" $NGINX_CONFIG_DIR/fastcgi.conf;
}
# }}}
# function change_redis_conf() {{{
function change_redis_conf()
{
    local redis_conf=$REDIS_CONFIG_DIR/redis.conf;
    local num=`sed -n "/$1/=" $redis_conf`;
    if [ "$num" = "" ];then
        echo "从${redis_conf}文件中查找pattern($1)失败";
        exit 1;
    fi

    sed -i.bak.$$ "${num[0]}s/$1/$2/" $redis_conf
    if [ $? != "0" ];then
        echo "在${redis_conf}文件中执行替换失败. pattern($1) ($2)";
        exit 1;
    fi
}
# }}}
# function init_redis_conf() {{{
function init_redis_conf()
{
# 启动redis服务
# ./bin/redis-server redis.conf
# 关闭服务：
# ./bin/redis-cli -p 6379 shutdown

    # 后台运行
    local pattern='^daemonize no$';
    change_redis_conf "$pattern" "daemonize yes"

    # 客户端闲置多长时间后断开连接，默认为0关闭此功能
    local pattern='^timeout 0$';
    change_redis_conf "$pattern" "timeout 300"

    # 设置redis日志级别，默认级别：notice
#local pattern='^loglevel notice$';
#change_redis_conf "$pattern" "loglevel verbose"

    # 设置日志文件的输出方式
    local pattern='^logfile ""$';
    change_redis_conf "$pattern" "logfile $(sed_quote2 $LOG_DIR/redis/redis.log)"

    # pid
    local pattern='^pidfile .\{0,\}$';
    change_redis_conf "$pattern" "pidfile $(sed_quote2 $BASE_DIR/run/redis.pid)"

    # dir ./
    local pattern='^dir .\{0,\}$';
    change_redis_conf "$pattern" "dir $(sed_quote2 $BASE_DIR/data/redis)"
    # http://www.linuxidc.com/Linux/2015-01/111364.htm

#    list-max-ziplist-entries 512
#    list-max-ziplist-value 64
#    tcp-keepalive 0 #tcp-keepalive 300

}
# }}}
# }}}
# {{{ is_installed functions
# {{{ function is_installed()
function is_installed()
{
    local func="is_installed_${1}"
    function_exists "$func"
    if [ "$?" != "0" ];then
        echo "error: 函数[${func}]未实现." >&2
        return 1;
    fi

    if [ -d "$2" ]; then
        deal_pkg_config_path "$2"
    fi

    $func

    if [ "$?" != "0" ];then
        return 1;
    fi

    deal_ld_library_path "$2"
    deal_path "$2"

    if [ "$?" != 0 ];then
        return 1;
    fi

}
# }}}
# {{{ function is_installed_jpeg()
function is_installed_jpeg()
{
    if [ ! -f "$JPEG_BASE/bin/djpeg" ];then
        return 1;
    fi
    local version=`$JPEG_BASE/bin/djpeg -verbose < /dev/null 2>&1|sed -n '1p' |awk '{ print $(NF-1); }'`
    if [ "$version" != "$JPEG_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_memcached()
function is_installed_memcached()
{
    if [ ! -f "$MEMCACHED_BASE/bin/memcached" ];then
        return 1;
    fi
    local version=`$MEMCACHED_BASE/bin/memcached -V |awk '{ print $NF; }'`
    if [ "$version" != "$MEMCACHED_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_redis()
function is_installed_redis()
{
    if [ ! -f "$REDIS_BASE/bin/redis-cli" ];then
        return 1;
    fi
    local version=`${REDIS_BASE}/bin/redis-cli --version |awk '{ print $2; }'`
    if [ "$version" != "$REDIS_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_gearmand()
function is_installed_gearmand()
{
    local FILENAME="$GEARMAND_BASE/lib/pkgconfig/gearmand.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$GEARMAND_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_tidy()
function is_installed_tidy()
{
    if [ ! -f "$TIDY_BASE/bin/tidy" ];then
        return 1;
    fi
    local version=`$TIDY_BASE/bin/tidy --version |awk '{ print $NF; }'`
    if [ "$version" != "$TIDY_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_sphinx()
function is_installed_sphinx()
{
    if [ ! -f "$SPHINX_BASE/bin/searchd" ];then
        return 1;
    fi
    local version=`LD_LIBRARY_PATH="$MYSQL_BASE/lib:$LD_LIBRARY_PATH" $SPHINX_BASE/bin/searchd -h|sed -n '1p'|awk -F'[ -]' '{ print $2; }'`
    if [ "$version" != "$SPHINX_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_sphinxclient()
function is_installed_sphinxclient()
{
    if [ ! -f "$SPHINX_CLIENT_BASE/include/sphinxclient.h" ];then
        return 1;
    fi
    # 没有版本比较
    return;
    # local version=`LD_LIBRARY_PATH="$MYSQL_BASE/lib:$LD_LIBRARY_PATH" $SPHINX_BASE/bin/searchd -h|sed -n '1p'|awk -F'[ -]' '{ print $2; }'`
    if [ "$version" != "$SPHINX_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libmcrypt()
function is_installed_libmcrypt()
{
    if [ ! -f "$LIBMCRYPT_BASE/bin/libmcrypt-config" ];then
        return 1;
    fi
    local version=`$LIBMCRYPT_BASE/bin/libmcrypt-config --version`
    if [ "$version" != "$LIBMCRYPT_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_gettext()
function is_installed_gettext()
{
    if [ ! -f "$LIBICONV_BASE/bin/gettext" ];then
        return 1;
    fi
    local version=`$LIBICONV_BASE/bin/gettext --version|sed -n '1s/^.\{1,\} \{1,\}\([0-9.]\{1,\}\)$/\1/p'`
    if [ "$version" != "$GETTEXT_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libiconv()
function is_installed_libiconv()
{
    if [ ! -f "$LIBICONV_BASE/bin/iconv" ];then
        return 1;
    fi
    local version=`$LIBICONV_BASE/bin/iconv --version|sed -n '1s/^.\{1,\}\([0-9]\{1,\}\(\.[0-9]\{1,\}\)\{1,2\}\).\{1,\}$/\1/p'`
    if [ "$version" != "$LIBICONV_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_pcre()
function is_installed_pcre()
{
    local FILENAME="$PCRE_BASE/lib/pkgconfig/libpcre.pc"
    if [ ! -f "$PCRE_BASE/bin/pcre-config" ];then
        return 1;
    fi
    # local version=`$PCRE_BASE/bin/pcre-config --version`
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$PCRE_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_openssl()
function is_installed_openssl()
{
    local FILENAME=""

    if [ -d "$OPENSSL_BASE/" ];then
        #FILENAME=`find $OPENSSL_BASE/lib*/pkgconfig -name openssl.pc|sed -n '1p'`
        FILENAME=`find $OPENSSL_BASE/ -name openssl.pc|sed -n '1p'`
    fi
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$OPENSSL_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_icu()
function is_installed_icu()
{
#    if [ ! -f "$ICU_BASE/bin/icu-config" ];then
#        return 1;
#    fi
#    local version=`$ICU_BASE/bin/icu-config --version|sed -n '/^[a-zA-Z0-9.]\{1,\}$/p'`
    local FILENAME="$ICU_BASE/lib/pkgconfig/icu-uc.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi

    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$ICU_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_boost()
function is_installed_boost()
{
    local FILENAME="${BOOST_BASE}/include/boost/version.hpp"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi

    local version=`sed -n '/^#define BOOST_LIB_VERSION "\([0-9_.]\{1,\}\)"$/{ s//\1/p;}' ${FILENAME}`
    if test `echo $version |awk -F_ "{print NF}"` = "2" ;then
        version="${version}_0"
    fi

    if [ "${version}" != "$BOOST_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_zlib()
function is_installed_zlib()
{
    local FILENAME="$ZLIB_BASE/lib/pkgconfig/zlib.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$ZLIB_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libzip()
function is_installed_libzip()
{
    local FILENAME="$LIBZIP_BASE/lib/pkgconfig/libzip.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion  $FILENAME`
    if [ "$version" != "$LIBZIP_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libxml2()
function is_installed_libxml2()
{
#    if [ ! -f "$LIBXML2_BASE/bin/xml2-config" ];then
#        return 1;
#    fi
#    local version=`$LIBXML2_BASE/bin/xml2-config --version`

    local FILENAME="$LIBXML2_BASE/lib/pkgconfig/libxml-2.0.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$LIBXML2_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libxslt()
function is_installed_libxslt()
{
    local FILENAME="$LIBXSLT_BASE/lib/pkgconfig/libxslt.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$LIBXSLT_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libevent()
function is_installed_libevent()
{
    local FILENAME=$LIBEVENT_BASE/lib/pkgconfig/libevent.pc;
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    version=${version%-*}
    if [ "$version" != "$LIBEVENT_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_expat()
function is_installed_expat()
{
    local FILENAME="$EXPAT_BASE/lib/pkgconfig/expat.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$EXPAT_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libpng()
function is_installed_libpng()
{
    local FILENAME="$LIBPNG_BASE/lib/pkgconfig/libpng.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$LIBPNG_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_openjpeg()
function is_installed_openjpeg()
{
    local FILENAME="$OPENJPEG_BASE/lib/pkgconfig/libopenjp2.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$OPENJPEG_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_sqlite()
function is_installed_sqlite()
{
    local FILENAME="$SQLITE_BASE/lib/pkgconfig/sqlite3.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME| tr . "\n" |awk '{printf "%02d\n",$0}'|tr -d "\n"`
    version=${version}00
    if [ "${version#*0}" != "$SQLITE_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_curl()
function is_installed_curl()
{
    local FILENAME="$CURL_BASE/lib/pkgconfig/libcurl.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$CURL_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_pkgconfig()
function is_installed_pkgconfig()
{
    if [ ! -f "$PKGCONFIG_BASE/bin/pkg-config" ];then
        return 1;
    fi
    local version=`$PKGCONFIG_BASE/bin/pkg-config --version`
    if [ "${version}" != "$PKGCONFIG_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_freetype()
function is_installed_freetype()
{
    if [ ! -f "$FREETYPE_BASE/bin/freetype-config" ];then
        return 1;
    fi
    local version=`$FREETYPE_BASE/bin/freetype-config --ftversion`
    if [ "${version}" != "$FREETYPE_VERSION" -a "${version%.0}" != "$FREETYPE_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_xproto()
function is_installed_xproto()
{
    local FILENAME="$XPROTO_BASE/lib/pkgconfig/xproto.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$XPROTO_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_macros()
function is_installed_macros()
{
    local FILENAME="$MACROS_BASE/share/pkgconfig/xorg-macros.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$MACROS_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_xcb_proto()
function is_installed_xcb_proto()
{
    local FILENAME="$XCB_PROTO_BASE/lib/pkgconfig/xcb-proto.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$XCB_PROTO_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libpthread_stubs()
function is_installed_libpthread_stubs()
{
    local FILENAME="$LIBPTHREAD_STUBS_BASE/lib/pkgconfig/pthread-stubs.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$LIBPTHREAD_STUBS_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libXau()
function is_installed_libXau()
{
    local FILENAME="$LIBXAU_BASE/lib/pkgconfig/xau.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$LIBXAU_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libxcb()
function is_installed_libxcb()
{
    local FILENAME="$LIBXCB_BASE/lib/pkgconfig/xcb.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$LIBXCB_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_kbproto()
function is_installed_kbproto()
{
    local FILENAME="$KBPROTO_BASE/lib/pkgconfig/kbproto.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$KBPROTO_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_inputproto()
function is_installed_inputproto()
{
    local FILENAME="$INPUTPROTO_BASE/lib/pkgconfig/inputproto.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$INPUTPROTO_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_xextproto()
function is_installed_xextproto()
{
    local FILENAME="$XEXTPROTO_BASE/lib/pkgconfig/xextproto.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$XEXTPROTO_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_xtrans()
function is_installed_xtrans()
{
    local FILENAME="$XTRANS_BASE/share/pkgconfig/xtrans.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$XTRANS_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_xf86bigfontproto()
function is_installed_xf86bigfontproto()
{
    local FILENAME="$XF86BIGFONTPROTO_BASE/lib/pkgconfig/xf86bigfontproto.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$XF86BIGFONTPROTO_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libX11()
function is_installed_libX11()
{
    local FILENAME="$LIBX11_BASE/lib/pkgconfig/x11.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$LIBX11_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libXpm()
function is_installed_libXpm()
{
    local FILENAME="$LIBXPM_BASE/lib/pkgconfig/xpm.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$LIBXPM_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_fontconfig()
function is_installed_fontconfig()
{
    local FILENAME="$FONTCONFIG_BASE/lib/pkgconfig/fontconfig.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$FONTCONFIG_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_gmp()
function is_installed_gmp()
{
    local FILENAME="$GMP_BASE/share/info/gmp.info"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`sed -n 's/^.\{1,\}version \{1,\}\([0-9.]\{1,\}\).$/\1/p' $FILENAME`
    if [ "${version}" != "$GMP_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_imap()
function is_installed_imap()
{
    local FILENAME="$IMAP_BASE/lib/libc-client.a"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    return;
#local version=`pkg-config --modversion $FILENAME`
#    if [ "${version}" != "$IMAP_VERSION" ];then
#        return 1;
#    fi
#    return;
}
# }}}
# {{{ function is_installed_kerberos()
function is_installed_kerberos()
{
    local FILENAME="$KERBEROS_BASE/lib/pkgconfig/krb5.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`PKG_CONFIG_PATH="$PKG_CONFIG_PATH" pkg-config --modversion $FILENAME`
    if [ "${version}" != "$KERBEROS_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libmemcached()
function is_installed_libmemcached()
{
    local FILENAME="$LIBMEMCACHED_BASE/lib/pkgconfig/libmemcached.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$LIBMEMCACHED_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_apr()
function is_installed_apr()
{
    local FILENAME="$APR_BASE/lib/pkgconfig/apr-1.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$APR_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_apr_util()
function is_installed_apr_util()
{
    local FILENAME="$APR_UTIL_BASE/lib/pkgconfig/apr-util-1.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$APR_UTIL_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_postgresql()
function is_installed_postgresql()
{
    local FILENAME="$POSTGRESQL_BASE/lib/pkgconfig/libpq.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$POSTGRESQL_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_apache()
function is_installed_apache()
{
    if [ ! -f "$APACHE_BASE/bin/httpd" ];then
        return 1;
    fi
    local version=`$APACHE_BASE/bin/httpd -v|sed -n '1p'|awk '{print $(NF-1);}'|awk -F/ '{print $(NF);}'`
    if [ "$version" != "$APACHE_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_nginx()
function is_installed_nginx()
{
    if [ ! -f "$NGINX_BASE/sbin/nginx" ];then
        return 1;
    fi
    local version=`$NGINX_BASE/sbin/nginx -v 2>&1|awk -F/ '{ print $NF; }'`
    if [ "$version" != "$NGINX_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_rsyslog()
function is_installed_rsyslog()
{
    if [ ! -f "$RSYSLOG_BASE/sbin/rsyslogd" ];then
        return 1;
    fi
    local version=`$RSYSLOG_BASE/sbin/rsyslogd -v 2>&1|sed -n '1{s/^rsyslogd \([0-9.]\{5,\}\),.\{0,\}$/\1/p;}'`
    if [ "$version" != "$RSYSLOG_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_liblogging()
function is_installed_liblogging()
{
    local FILENAME="$LIBLOGGING_BASE/lib/pkgconfig/liblogging-stdlog.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$LIBLOGGING_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libgcrypt()
function is_installed_libgcrypt()
{
    local FILENAME="$LIBGCRYPT_BASE/bin/libgcrypt-config"
    if [ ! -f $FILENAME ];then
        return 1;
    fi
    local version=`$FILENAME --version`
    if [ "$version" != "$LIBGCRYPT_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libgpg_error()
function is_installed_libgpg_error()
{
    local FILENAME="$LIBGPG_ERROR_BASE/bin/gpg-error-config"
    if [ ! -f $FILENAME ];then
        return 1;
    fi
    local version=`$FILENAME --version`
    if [ "$version" != "$LIBGPG_ERROR_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libestr()
function is_installed_libestr()
{
    local FILENAME="$LIBESTR_BASE/lib/pkgconfig/libestr.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$LIBESTR_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_json()
function is_installed_json()
{
    local FILENAME="$JSON_BASE/lib/pkgconfig/json-c.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$JSON_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libfastjson()
function is_installed_libfastjson()
{
    local FILENAME="$LIBFASTJSON_BASE/lib/pkgconfig/libfastjson.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$LIBFASTJSON_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libgd()
function is_installed_libgd()
{
    local FILENAME="$LIBGD_BASE/lib/pkgconfig/gdlib.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$LIBGD_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_ImageMagick()
function is_installed_ImageMagick()
{
    local FILENAME="$IMAGEMAGICK_BASE/lib/pkgconfig/ImageMagick.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "${IMAGEMAGICK_VERSION%-*}" ];then
        return 1;
    fi
    local version=`sed -n 's/^#define MAGICKCORE_VERSION "\([0-9.-]\{1,\}\)"$/\1/p' ${IMAGEMAGICK_BASE}/include/ImageMagick-${IMAGEMAGICK_VERSION%%.*}/MagickCore/magick-baseconfig.h`;
    if [ "$version" != "${IMAGEMAGICK_VERSION}" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_php()
function is_installed_php()
{
    if [ ! -f "$PHP_BASE/bin/php" ];then
        return 1;
    fi
    local version=`$PHP_BASE/bin/php -v | sed -n '1p' | awk '{print $2;}'`
    if [ "$version" != "$PHP_VERSION" ];then
        return 1;
    fi
}
# }}}
# {{{ function is_installed_php_extension()
function is_installed_php_extension()
{
    if [ ! -f "$PHP_BASE/bin/php" ];then
        return 1;
    fi

    $PHP_BASE/bin/php -m | grep -q "^$1\$"
    if [ "$?" != "0" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_mysql()
function is_installed_mysql()
{
    if [ ! -f "$MYSQL_BASE/bin/mysql_config" ];then
        return 1;
    fi
    local version=`$MYSQL_BASE/bin/mysql_config --version`
    if [ "$version" != "$MYSQL_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_qrencode()
function is_installed_qrencode()
{
    if [ ! -f "$LIBQRENCODE_BASE/bin/qrencode" ];then
        return 1;
    fi
    local version=`$LIBQRENCODE_BASE/bin/qrencode --version 2>&1|sed -n '1p'| awk  '{ print $NF;}'`
    if [ "$version" != "$LIBQRENCODE_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libsodium()
function is_installed_libsodium()
{
    local FILENAME="$LIBSODIUM_BASE/lib/pkgconfig/libsodium.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$LIBSODIUM_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_zeromq()
function is_installed_zeromq()
{
    local FILENAME="$ZEROMQ_BASE/lib/pkgconfig/libzmq.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$ZEROMQ_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_hiredis()
function is_installed_hiredis()
{
    local FILENAME="$HIREDIS_BASE/lib/pkgconfig/hiredis.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$HIREDIS_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libunwind()
function is_installed_libunwind()
{
    local FILENAME="$LIBUNWIND_BASE/lib/pkgconfig/libunwind.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$LIBUNWIND_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_rabbitmq_c()
function is_installed_rabbitmq_c()
{
    local FILENAME=""

    if [ -d "$RABBITMQ_C_BASE/" ];then
        FILENAME=`find $RABBITMQ_C_BASE/ -name librabbitmq.pc|sed -n '1p'`
    fi

    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$RABBITMQ_C_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libmaxminddb()
function is_installed_libmaxminddb()
{
    local FILENAME="$LIBMAXMINDDB_BASE/lib/pkgconfig/libmaxminddb.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$LIBMAXMINDDB_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_geoipupdate()
function is_installed_geoipupdate()
{
    if [ ! -f "$GEOIPUPDATE_BASE/bin/geoipupdate" ];then
        return 1;
    fi
    local version=`$GEOIPUPDATE_BASE/bin/geoipupdate -V|awk '{print $NF;}'`
    if [ "$version" != "$GEOIPUPDATE_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_nasm()
function is_installed_nasm()
{
    local FILENAME="$NASM_BASE/bin/nasm"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`$FILENAME -v|awk '{print $3;}'`
    if [ "$version" != "$NASM_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libjpeg()
function is_installed_libjpeg()
{
    local FILENAME="$LIBJPEG_BASE/lib/pkgconfig/libjpeg.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$LIBJPEG_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_cairo()
function is_installed_cairo()
{
    local FILENAME="$CAIRO_BASE/lib/pkgconfig/cairo.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$CAIRO_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_poppler()
function is_installed_poppler()
{
    local FILENAME="$POPPLER_BASE/lib/pkgconfig/poppler.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$POPPLER_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_pixman()
function is_installed_pixman()
{
    local FILENAME="$PIXMAN_BASE/lib/pkgconfig/pixman-1.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$PIXMAN_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_glib()
function is_installed_glib()
{
    local FILENAME="$GLIB_BASE/lib/pkgconfig/glib-2.0.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$GLIB_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libffi()
function is_installed_libffi()
{
    local FILENAME="$LIBFFI_BASE/lib/pkgconfig/libffi.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$LIBFFI_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_util_linux()
function is_installed_util_linux()
{
    local FILENAME="$UTIL_LINUX_BASE/lib/pkgconfig/mount.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$UTIL_LINUX_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_harfbuzz()
function is_installed_harfbuzz()
{
    local FILENAME="$HARFBUZZ_BASE/lib/pkgconfig/harfbuzz.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$HARFBUZZ_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_pango()
function is_installed_pango()
{
    local FILENAME="$PANGO_BASE/lib/pkgconfig/pango.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$PANGO_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_fontforge()
function is_installed_fontforge()
{
    local FILENAME="$FONTFORGE_BASE/lib/pkgconfig/libfontforge.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    # 这个版本与包名称中的不一致，这里不比较了，只要安装了，就不更新
#    if [ "$version" != "$FONTFORGE_VERSION" ];then
#        return 1;
#    fi
    return;
}
# }}}
# {{{ function is_installed_pdf2htmlEX()
function is_installed_pdf2htmlEX()
{
    local FILENAME="$PDF2HTMLEX_BASE/bin/pdf2htmlEX"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    # 前面的优先级高
    local version=`LD_LIBRARY_PATH="$POPPLER_BASE/lib:/usr/local/lib64:/usr/lib64" $PDF2HTMLEX_BASE/bin/pdf2htmlEX --version 2>&1|sed -n '1p' |awk '{print $NF;}'`

    if [ "$version" != "$PDF2HTMLEX_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# }}}
# {{{ compile functions
# {{{ function compile_re2c()
function compile_re2c()
{
    is_installed re2c $RE2C_BASE
    if [ "$?" = "0" ];then
        return;
    fi


#    which re2c > /dev/null 2>&1
#    if [ "$?" = "0" ] && [ `re2c -V` -gt "001304" ] ;then
#        return;
#    fi

    RE2C_CONFIGURE="
    ./configure --prefix=$RE2C_BASE
    "

    compile "re2c" "$RE2C_FILE_NAME" "re2c-$RE2C_VERSION" "$RE2C_BASE" "RE2C_CONFIGURE"
}
# }}}
# {{{ function compile_pkgconfig()
function compile_pkgconfig()
{
    is_installed pkgconfig "$PKGCONFIG_BASE"
    if [ "$?" = "0" ];then
        export PKG_CONFIG="$PKGCONFIG_BASE/bin/pkg-config"
        return;
    fi

    PKGCONFIG_CONFIGURE="
    ./configure --prefix=$PKGCONFIG_BASE
    "
    #--with-internal-glib

    compile "pkg-config" "$PKGCONFIG_FILE_NAME" "pkg-config-$PKGCONFIG_VERSION" "$PKGCONFIG_BASE" "PKGCONFIG_CONFIGURE"

    export PKG_CONFIG="$PKGCONFIG_BASE/bin/pkg-config"
}
# }}}
# {{{ function compile_pcre()
function compile_pcre()
{
    is_installed pcre $PCRE_BASE
    if [ "$?" = "0" ];then
        return;
    fi

    PCRE_CONFIGURE="
    ./configure --prefix=$PCRE_BASE \
                --enable-utf8 \
                --enable-unicode-properties
    "
    # --enable-pcre16 --enable-pcre32 --enable-unicode-properties --enable-utf

    compile "pcre" "$PCRE_FILE_NAME" "pcre-$PCRE_VERSION" "$PCRE_BASE" "PCRE_CONFIGURE"
}
# }}}
# {{{ function compile_openssl()
function compile_openssl()
{
    is_installed openssl "$OPENSSL_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    OPENSSL_CONFIGURE="
    ./config --prefix=$OPENSSL_BASE threads shared -fPIC
    "
    # -darwin-i386-cc

    compile "openssl" "$OPENSSL_FILE_NAME" "openssl-$OPENSSL_VERSION" "$OPENSSL_BASE" "OPENSSL_CONFIGURE"
}
# }}}
# {{{ function compile_icu()
function compile_icu()
{
    is_installed icu "$ICU_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    export LD_LIBRARY_PATH
    ICU_CONFIGURE="
        configure_icu_command
    "

    compile "icu" "$ICU_FILE_NAME" "icu/source" "$ICU_BASE" "ICU_CONFIGURE"
    export -n LD_LIBRARY_PATH
    if [ "$OS_NAME" = "Darwin" ];then
        repair_dynamic_shared_library $ICU_BASE/lib "libicu*dylib"
    fi

}
# }}}
# {{{ function compile_boost()
function compile_boost()
{
    compile_icu

    is_installed boost "$BOOST_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    #yum install python-devel bzip2-devel
    #yum install gperf libevent-devel libuuid-devel

    decompress $BOOST_FILE_NAME
    if [ "$?" != "0" ];then
        echo "decompress file error. FILE_NAME: $BOOST_FILE_NAME" >&2
        exit 1;
        #return 1;
    fi

    cd "boost_${BOOST_VERSION}"
    if [ "$?" != "0" ];then
        echo "cd boost_${BOOST_VERSION} failed." >&2;
        exit 1;
    fi

    local COMMAND="./bootstrap.sh --with-icu=$ICU_BASE --prefix=$BOOST_BASE && ./b2 install --with-program_options"
    echo "configure command: "
    echo ${COMMAND}
    echo ""
    ./bootstrap.sh --with-icu=$ICU_BASE --prefix=$BOOST_BASE && ./b2 install --with-program_options

    if [ "$?" != "0" ];then
        echo "Install boost failed." >&2;
        exit 1;
    fi

    cd ..
    /bin/rm -rf "boost_${BOOST_VERSION}"

#    atomic
#    chrono
#    container
#    context
#    coroutine
#    coroutine2
#    date_time
#    exception
#    filesystem
#    graph
#    graph_parallel
#    iostreams
#    locale
#    log
#    math
#    mpi
#    program_options
#    python
#    random
#    regex
#    serialization
#    signals
#    system
#    test
#    thread
#    timer
#    wave
    if [ "$OS_NAME" = "Darwin" ];then
        repair_dynamic_shared_library $BOOST_BASE/lib "libboost*dylib"
    fi

}
# }}}
# {{{ function compile_zlib()
function compile_zlib()
{
    is_installed zlib "$ZLIB_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    # CFLAGS="-O3 -fPIC" \
    ZLIB_CONFIGURE="
    ./configure --prefix=$ZLIB_BASE
    "
    compile "zlib" "$ZLIB_FILE_NAME" "zlib-$ZLIB_VERSION" "$ZLIB_BASE" "ZLIB_CONFIGURE"
}
# }}}
# {{{ function compile_libzip()
function compile_libzip()
{
    compile_zlib

    is_installed libzip "$LIBZIP_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBZIP_CONFIGURE="
    ./configure --prefix=$LIBZIP_BASE --with-zlib=$ZLIB_BASE
    "
    compile "libzip" "$LIBZIP_FILE_NAME" "libzip-$LIBZIP_VERSION" "$LIBZIP_BASE" "LIBZIP_CONFIGURE"
}
# }}}
# {{{ function compile_libiconv()
function compile_libiconv()
{
    is_installed libiconv "$LIBICONV_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBICONV_CONFIGURE="
    ./configure --prefix=$LIBICONV_BASE \
    "
    #  --with-iconv-prefix=$LIBICONV_BASE \

    compile "libiconv" "$LIBICONV_FILE_NAME" "libiconv-$LIBICONV_VERSION" "$LIBICONV_BASE" "LIBICONV_CONFIGURE"
}
# }}}
# {{{ function compile_gettext()
function compile_gettext()
{
    is_installed gettext "$GETTEXT_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    GETTEXT_CONFIGURE="
    ./configure --prefix=$GETTEXT_BASE \
                --enable-threads \
                --disable-java \
                --disable-native-java \
                --disable-nls \
                --without-emacs
    "

    compile "gettext" "$GETTEXT_FILE_NAME" "gettext-$GETTEXT_VERSION" "$GETTEXT_BASE" "GETTEXT_CONFIGURE"
}
# }}}
# {{{ function compile_libxml2()
function compile_libxml2()
{
    compile_zlib
    compile_libiconv

    is_installed libxml2 "$LIBXML2_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBXML2_CONFIGURE="
    ./configure --prefix=$LIBXML2_BASE \
                --with-iconv=$LIBICONV_BASE \
                --with-zlib=$ZLIB_BASE \
                $( [ "$OS_NAME" = "Darwin" ] && echo "--without-lzma") \
                --without-python
    "
# xmlIO.c:1450:52: error: use of undeclared identifier 'LZMA_OK' mac上2.9.3报错. 加 --without-lzma
#或者 sed -n 's/LZMA_OK/LZMA_STREAM_END/p' xmlIO.c

    compile "libxml2" "$LIBXML2_FILE_NAME" "libxml2-$LIBXML2_VERSION" "$LIBXML2_BASE" "LIBXML2_CONFIGURE"
}
# }}}
# {{{ function compile_libxslt()
function compile_libxslt()
{
    compile_libxml2

    is_installed libxslt "$LIBXSLT_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBXSLT_CONFIGURE="
    ./configure --prefix=$LIBXSLT_BASE \
                --with-libxml-prefix=$LIBXML2_BASE
    "

    compile "libxslt" "$LIBXSLT_FILE_NAME" "libxslt-$LIBXSLT_VERSION" "$LIBXSLT_BASE" "LIBXSLT_CONFIGURE"
}
# }}}
# {{{ function compile_tidy()
function compile_tidy()
{
    compile_libxslt

    is_installed tidy "$TIDY_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    export PATH="$LIBXSLT_BASE/bin:$PATH"

    TIDY_CONFIGURE="
    cmake ../.. -DCMAKE_INSTALL_PREFIX=$TIDY_BASE
    "
    # 5.2.0 language_es.h:1: 错误：程序中有游离的 ‘\357’
    # src/language_en_gb.h
    # src/language_es.h
    # src/language_zh_cn.h
    # src/language_fr.h
    #for i in `find src/ -type f`; do { grep -q $'^\xef\xbb\xbf' $i; if [ "$?" = "0" ];then echo sed -i '1s/^\xef\xbb\xbf//' $i; fi; } done


    compile "tidy" "$TIDY_FILE_NAME" "tidy-html5-$TIDY_VERSION/build/cmake" "$TIDY_BASE" "TIDY_CONFIGURE"
    if [ "$OS_NAME" = "Darwin" ];then
        repair_dynamic_shared_library $TIDY_BASE/lib "lib*tidy*.dylib"
    fi
}
# }}}
# {{{ function compile_sphinx()
function compile_sphinx()
{
    compile_mysql

    is_installed sphinx "$SPHINX_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    SPHINX_CONFIGURE="
    ./configure --prefix=$SPHINX_BASE \
                --sysconfdir=$BASE_DIR/etc/sphinx
                --with-mysql=$MYSQL_BASE
    "

    compile "sphinx" "$SPHINX_FILE_NAME" "sphinx-${SPHINX_VERSION}-release" "$SPHINX_BASE" "SPHINX_CONFIGURE"
}
# }}}
# {{{ function compile_sphinxclient()
function compile_sphinxclient()
{
    is_installed sphinxclient "$SPHINX_CLIENT_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    SPHINXCLIENT_CONFIGURE="
    configure_sphinxclient_command
    "

    compile "sphinxclient" "$SPHINX_FILE_NAME" "sphinx-${SPHINX_VERSION}-release/api/libsphinxclient" "$SPHINX_CLIENT_BASE" "SPHINXCLIENT_CONFIGURE"
}
# }}}
# {{{ function compile_json()
function compile_json()
{
    is_installed json "$JSON_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    JSON_CONFIGURE="
    ./configure --prefix=$JSON_BASE
    "

    compile "json-c" "$JSON_FILE_NAME" "json-c-$JSON_VERSION" "$JSON_BASE" "JSON_CONFIGURE"
}
# }}}
# {{{ function compile_libfastjson()
function compile_libfastjson()
{
    is_installed libfastjson "$LIBFASTJSON_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBFASTJSON_CONFIGURE="
        ./configure --prefix=$LIBFASTJSON_BASE
    "

    compile "libfastjson" "$LIBFASTJSON_FILE_NAME" "libfastjson-$LIBFASTJSON_VERSION" "$LIBFASTJSON_BASE" "LIBFASTJSON_CONFIGURE"
}
# }}}
# {{{ function compile_libmcrypt()
function compile_libmcrypt()
{
    is_installed libmcrypt "$LIBMCRYPT_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBMCRYPT_CONFIGURE="
    ./configure --prefix=$LIBMCRYPT_BASE
    "

    compile "libmcrypt" "$LIBMCRYPT_FILE_NAME" "libmcrypt-$LIBMCRYPT_VERSION" "$LIBMCRYPT_BASE" "LIBMCRYPT_CONFIGURE"
}
# }}}
# {{{ function compile_libevent()
function compile_libevent()
{
    compile_openssl

    is_installed libevent "$LIBEVENT_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBEVENT_CONFIGURE="
    configure_libevent_command
    "

    compile "libevent" "$LIBEVENT_FILE_NAME" "libevent-release-${LIBEVENT_VERSION}-stable" "$LIBEVENT_BASE" "LIBEVENT_CONFIGURE"
}
# }}}
# {{{ function compile_jpeg()
function compile_jpeg()
{
    is_installed jpeg "$JPEG_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    JPEG_CONFIGURE="
    ./configure --prefix=$JPEG_BASE --enable-shared --enable-static
    "

    compile "jpeg" "$JPEG_FILE_NAME" "jpeg-$JPEG_VERSION" "$JPEG_BASE" "JPEG_CONFIGURE"
}
# }}}
# {{{ function compile_pdf2htmlEX()
function compile_pdf2htmlEX()
{
    compile_poppler
    compile_cairo
    compile_fontforge

    is_installed pdf2htmlEX "$PDF2HTMLEX_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    PDF2HTMLEX_CONFIGURE="
        configure_pdf2htmlEX_command
    "

    compile "pdf2htmlEX" "$PDF2HTMLEX_FILE_NAME" "pdf2htmlEX-$PDF2HTMLEX_VERSION" "$PDF2HTMLEX_BASE" "PDF2HTMLEX_CONFIGURE"
}
# }}}
# {{{ function compile_poppler()
function compile_poppler()
{
    compile_libpng
    compile_libjpeg
    compile_openjpeg
    compile_cairo
    compile_fontforge
#    compile_curl
#    compile_libcurl
#    compile_libtiff
#complie_nss

    is_installed poppler "$POPPLER_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

#    Building poppler with support for:
#    font configuration:  fontconfig
#    splash output:       yes
#    cairo output:        no (requires cairo >= 1.10.0)
#    qt4 wrapper:         no
#    qt5 wrapper:         no
#    glib wrapper:        no (requires cairo output)
#    introspection:     no
#    cpp wrapper:         yes
#    use gtk-doc:         no
#    use libjpeg:         yes
#    use libpng:          yes
#    use libtiff:         no
#    use zlib compress:   yes
#    use zlib uncompress: no
#    use nss:             no
#    use libcurl:         no
#    use libopenjpeg:     no
#    use cms:             no
#    command line utils:  yes


    POPPLER_CONFIGURE="
     ./configure --prefix=$POPPLER_BASE \
                 --enable-xpdf-headers
    "

    compile "poppler" "$POPPLER_FILE_NAME" "poppler-$POPPLER_VERSION" "$POPPLER_BASE" "POPPLER_CONFIGURE"
}
# }}}
# {{{ function compile_cairo()
function compile_cairo()
{
    compile_libpng
    compile_pixman
    [ "$OS_NAME" != "Darwin" ] && compile_glib
    compile_fontconfig

    is_installed cairo "$CAIRO_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    CAIRO_CONFIGURE="
     ./configure --prefix=$CAIRO_BASE \
                 --disable-dependency-tracking
    "

    compile "cairo" "$CAIRO_FILE_NAME" "cairo-$CAIRO_VERSION" "$CAIRO_BASE" "CAIRO_CONFIGURE"
}
# }}}
# {{{ function compile_openjpeg()
function compile_openjpeg()
{
    is_installed openjpeg "$OPENJPEG_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    OPENJPEG_CONFIGURE="
     cmake ./ -DCMAKE_INSTALL_PREFIX=$OPENJPEG_BASE
    "

    compile "openjpeg" "$OPENJPEG_FILE_NAME" "openjpeg-$OPENJPEG_VERSION" "$OPENJPEG_BASE" "OPENJPEG_CONFIGURE"
}
# }}}
# {{{ function compile_fontforge()
function compile_fontforge()
{
    # yum install -y libtool-ltdl libtool-ltdl-devel
    compile_pkgconfig
    compile_freetype
    compile_libiconv
    compile_libpng
    compile_pango
    compile_cairo

    is_installed fontforge "$FONTFORGE_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    local old_path="$PATH"
    FONTFORGE_CONFIGURE="
        configure_fontforge_command
    "

    compile "fontforge" "$FONTFORGE_FILE_NAME" "fontforge-$FONTFORGE_VERSION" "$FONTFORGE_BASE" "FONTFORGE_CONFIGURE"
    export PATH="$old_path"
}
# }}}
# {{{ function compile_pango()
function compile_pango()
{
    compile_cairo
    [ "$OS_NAME" != "Darwin" ] && compile_glib
    compile_freetype
    compile_fontconfig

    is_installed pango "$PANGO_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    PANGO_CONFIGURE="
        ./configure --prefix=$PANGO_BASE
    "

    compile "pango" "$PANGO_FILE_NAME" "pango-$PANGO_VERSION" "$PANGO_BASE" "PANGO_CONFIGURE"
}
# }}}
# {{{ function compile_memcached()
function compile_memcached()
{
    compile_libevent

    is_installed memcached "$MEMCACHED_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    MEMCACHED_CONFIGURE="
    ./configure --prefix=$MEMCACHED_BASE \
                --with-libevent=$LIBEVENT_BASE \
                $( echo "$HOST_TYPE"|grep -q x86_64 && echo "--enable-64bit" )
    "
                # --enable-dtrace

    compile "memcached" "$MEMCACHED_FILE_NAME" "memcached-$MEMCACHED_VERSION" "$MEMCACHED_BASE" "MEMCACHED_CONFIGURE"
}
# }}}
# {{{ function compile_redis()
function compile_redis()
{
    is_installed redis "$REDIS_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    REDIS_CONFIGURE="
        configure_redis_command
    "
    compile "redis" "$REDIS_FILE_NAME" "redis-$REDIS_VERSION" "$REDIS_BASE" "REDIS_CONFIGURE" "after_redis_make_install"
}
# }}}
# {{{ function compile_gearmand()
function compile_gearmand()
{
    compile_openssl
    compile_libevent
    compile_curl
    compile_boost
    #yum install boost boost-devel
    #yum install gperf

    is_installed gearmand "$GEARMAND_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    GEARMAND_CONFIGURE="
        configure_gearmand_command
    "
    compile "gearmand" "$GEARMAND_FILE_NAME" "gearmand-$GEARMAND_VERSION" "$GEARMAND_BASE" "GEARMAND_CONFIGURE"
}
# }}}
# {{{ function configure_hiredis_command()
function configure_hiredis_command()
{
    # 没有configure
    # 本来要make PREFIX=... install,这里改了Makefile里的PREFIX，就不需要了
    sed -i.bak "s/$(sed_quote2 'PREFIX?=/usr/local')/$(sed_quote2 PREFIX?=$HIREDIS_BASE)/" Makefile
}
# }}}
# {{{ function configure_redis_command()
function configure_redis_command()
{
    # 没有configure
    # 本来要make PREFIX=... install,这里改了Makefile里的PREFIX，就不需要了
    sed -i.bak "s/$(sed_quote2 'PREFIX?=/usr/local')/$(sed_quote2 PREFIX?=$REDIS_BASE)/" src/Makefile

    # 3.2.7版本要编译报错 undefined reference to `clock_gettime'
    if [ "$REDIS_VERSION" = "3.2.7" ] ; then
        if [ "$OS_NAME" = "Linux" ] ; then
            local tmp_str=""
            if echo "$HOST_TYPE"|grep -q x86_64 ; then
                tmp_str="64"
            fi
            local file_name=/usr/lib${tmp_str}/librt.so
            if [ ! -f "$file_name" ]; then
                echo "$file_name file not exists" >&2
            fi
            # 查找是否加入了librt.so
            sed -n '/^ifeq (\$(MALLOC),jemalloc)$/,/^endif$/p' src/Makefile|grep -q librt.so
            if [ "$?" = "1" ] ;then
                local tab=$'\011'
                sed -i.bak "/^ifeq (\$(MALLOC),jemalloc)$/,/^endif$/{/^endif$/{i \
                    ${tab}FINAL_LIBS+= $file_name
                };}" src/Makefile

            fi
        fi
    fi
}
# }}}
# {{{ function configure_gearmand_command()
function configure_gearmand_command()
{
    # 没有configure
    if [ ! -f "./configure" ]; then
        # 执行报错，就只能下载有configure的包了
        ./bootstap.sh
        if [ "$?" != "0" ];then
            return 1;
        fi
    fi
    CPPFLAGS="$(get_cppflags $LIBEVENT_BASE/include $CURL_BASE/include $BOOST_BASE/include)" \
    LDFLAGS="$(get_ldflags $LIBEVENT_BASE/lib $CURL_BASE/lib $BOOST_BASE/lib)" \
    ./configure --prefix=$GEARMAND_BASE \
                --enable-ssl \
                --with-mysql=no \
                --with-boost=$( is_installed_boost && echo ${BOOST_BASE} || echo yes ) \
                --with-openssl=$OPENSSL_BASE \

                #--enable-cyassl \
                #--with-curl-prefix=$CURL_BASE # 加上后make时报错 Makefile:2138: *** missing separator. Stop.
                #--with-boost-libdir=${BOOST_BASE}/lib \
                #--enable-jobserver[=no/yes/#]
                #--with-drizzled=
                #--with-sqlite3=
                #--with-postgresql=
                #--with-memcached=
                #--with-sphinx-build=
                #--with-lcov=
                #--with-genhtml=

}
# }}}
# {{{ function after_redis_make_install()
function after_redis_make_install()
{
    mkdir -p $REDIS_CONFIG_DIR
    if [ "$?" != "0" ];then
        echo "mkdir error. commamnd: mkdir -p $REDIS_CONFIG_DIR" >&2
        return 1;
    fi

    cp redis.conf $REDIS_CONFIG_DIR/
    if [ "$?" != "0" ];then
        echo "copy file error. commamnd: cp redis.conf $REDIS_CONFIG_DIR/" >&2
        return 1;
    fi

    cp sentinel.conf $REDIS_CONFIG_DIR/
    if [ "$?" != "0" ];then
        echo "copy file error. commamnd: cp sentinel.conf $REDIS_CONFIG_DIR/" >&2
        return 1;
    fi

    init_redis_conf
}
# }}}
# {{{ function compile_expat()
function compile_expat()
{
    is_installed expat "$EXPAT_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    EXPAT_CONFIGURE="
    ./configure --prefix=$EXPAT_BASE
    "

    compile "expat" "$EXPAT_FILE_NAME" "expat-$EXPAT_VERSION" "$EXPAT_BASE" "EXPAT_CONFIGURE"
}
# }}}
# {{{ function compile_libpng()
function compile_libpng()
{
    compile_zlib

    is_installed libpng "$LIBPNG_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBPNG_CONFIGURE="
    ./configure --prefix=$LIBPNG_BASE \
                --with-zlib-prefix=$ZLIB_BASE
    "
    # --with-libpng-prefix

    compile "libpng" "$LIBPNG_FILE_NAME" "libpng-$LIBPNG_VERSION" "$LIBPNG_BASE" "LIBPNG_CONFIGURE"
}
# }}}
# {{{ function compile_sqlite()
function compile_sqlite()
{
    is_installed sqlite "$SQLITE_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    SQLITE_CONFIGURE="
    ./configure --prefix=$SQLITE_BASE --enable-json1 --enable-session --enable-fts5
    "

    compile "sqlite" "$SQLITE_FILE_NAME" "sqlite-autoconf-$SQLITE_VERSION" "$SQLITE_BASE" "SQLITE_CONFIGURE"
}
# }}}
# {{{ function compile_curl()
function compile_curl()
{
    compile_zlib
    compile_openssl

    is_installed curl "$CURL_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    CURL_CONFIGURE="
        configure_curl_command
    "
    # --disable-debug --enable-optimize

    compile "curl" "$CURL_FILE_NAME" "curl-$CURL_VERSION" "$CURL_BASE" "CURL_CONFIGURE"
}
# }}}
# {{{ function compile_freetype()
function compile_freetype()
{
    # 强制安装时，传一个参数，不安装harfbuzz,
    local is_force="$1"
    if [ "$is_force" = "" ]; then
    compile_harfbuzz
    fi
    compile_zlib
    compile_libpng

    is_installed freetype "$FREETYPE_BASE"
    if [ "$is_force" != "1" -a "$?" = "0" ];then
        return;
    fi

    FREETYPE_CONFIGURE="
    ./configure --prefix=$FREETYPE_BASE \
                --with-zlib=yes \
                --with-png=yes
    "
    #--with-bzip2=yes

    compile "freetype" "$FREETYPE_FILE_NAME" "freetype-$FREETYPE_VERSION" "$FREETYPE_BASE" "FREETYPE_CONFIGURE"
}
# }}}
# {{{ function compile_harfbuzz()
function compile_harfbuzz()
{
    [ "$OS_NAME" != "Darwin" ] && compile_glib
    compile_icu

    is_installed freetype "$FREETYPE_BASE"
    if [ "$?" != "0" ];then
        compile_freetype 1
    fi

    is_installed harfbuzz "$HARFBUZZ_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    HARFBUZZ_CONFIGURE="
    configure_harfbuzz_command
    "

    compile "harfbuzz" "$HARFBUZZ_FILE_NAME" "harfbuzz-$HARFBUZZ_VERSION" "$HARFBUZZ_BASE" "HARFBUZZ_CONFIGURE"

    #安装完成后，强制重新装备freetype
    compile_freetype 1
}
# }}}
# {{{ function compile_glib()
function compile_glib()
{
    compile_zlib
    # 使用这个，报错 checking for Unicode support in PCRE... no , 只能使用内部自己的
    #compile_pcre
    compile_libiconv
    compile_libffi

    if [ "$OS_NAME" != "Darwin" ]; then
        # 需要libmount,没有时，才编译
        pkg-config --modversion mount >/dev/null 2>&1
        if [ "$?" != "0" ]; then
            compile_util_linux
        fi
    fi

    is_installed glib "$GLIB_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    GLIB_CONFIGURE="
    ./configure --prefix=$GLIB_BASE \
                 --with-pcre=internal
    "
                 #--with-pcre=system \
                 #--with-threads=posix \
                 #--with-gio-module-dir=  \
                 #--with-libiconv=

    compile "glib" "$GLIB_FILE_NAME" "glib-$GLIB_VERSION" "$GLIB_BASE" "GLIB_CONFIGURE"
}
# }}}
# {{{ function compile_libffi()
function compile_libffi()
{
    is_installed libffi "$LIBFFI_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBFFI_CONFIGURE="
        configure_libffi_command
    "

    compile "libffi" "$LIBFFI_FILE_NAME" "libffi-$LIBFFI_VERSION" "$LIBFFI_BASE" "LIBFFI_CONFIGURE"
}
# }}}
# {{{ function compile_util_linux()
function compile_util_linux()
{
    is_installed util_linux "$UTIL_LINUX_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    UTIL_LINUX_CONFIGURE="
        ./configure --prefix=$UTIL_LINUX_BASE
    "

    compile "util-linux" "$UTIL_LINUX_FILE_NAME" "util-linux-$UTIL_LINUX_VERSION" "$UTIL_LINUX_BASE" "UTIL_LINUX_CONFIGURE"
}
# }}}
# {{{ function compile_xproto()
function compile_xproto()
{
    is_installed xproto "$XPROTO_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    XPROTO_CONFIGURE="
    ./configure --prefix=$XPROTO_BASE
    "

    compile "xproto" "$XPROTO_FILE_NAME" "xproto-$XPROTO_VERSION" "$XPROTO_BASE" "XPROTO_CONFIGURE"
}
# }}}
# {{{ function compile_macros()
function compile_macros()
{
    compile_xproto

    is_installed macros "$MACROS_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    MACROS_CONFIGURE="
    ./configure --prefix=$MACROS_BASE
    "

    compile "util-macros" "$MACROS_FILE_NAME" "util-macros-$MACROS_VERSION" "$MACROS_BASE" "MACROS_CONFIGURE"
}
# }}}
# {{{ function compile_xcb_proto()
function compile_xcb_proto()
{
    is_installed xcb_proto "$XCB_PROTO_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    XCB_PROTO_CONFIGURE="
    ./configure --prefix=$XCB_PROTO_BASE
    "

    compile "xcb-proto" "$XCB_PROTO_FILE_NAME" "xcb-proto-$XCB_PROTO_VERSION" "$XCB_PROTO_BASE" "XCB_PROTO_CONFIGURE"
}
# }}}
# {{{ function compile_libpthread_stubs()
function compile_libpthread_stubs()
{
    is_installed libpthread_stubs "$LIBPTHREAD_STUBS_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBPTHREAD_STUBS_CONFIGURE="
    ./configure --prefix=$LIBPTHREAD_STUBS_BASE
    "

    compile "libpthread-stubs" "$LIBPTHREAD_STUBS_FILE_NAME" "libpthread-stubs-$LIBPTHREAD_STUBS_VERSION" "$LIBPTHREAD_STUBS_BASE" "LIBPTHREAD_STUBS_CONFIGURE"
}
# }}}
# {{{ function compile_libXau()
function compile_libXau()
{
    is_installed libXau "$LIBXAU_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBXAU_CONFIGURE="
    ./configure --prefix=$LIBXAU_BASE
    "

    compile "libXau" "$LIBXAU_FILE_NAME" "libXau-$LIBXAU_VERSION" "$LIBXAU_BASE" "LIBXAU_CONFIGURE"
}
# }}}
# {{{ function compile_libxcb()
function compile_libxcb()
{
    compile_libpthread_stubs

    is_installed libxcb "$LIBXCB_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBXCB_CONFIGURE="
    ./configure --prefix=$LIBXCB_BASE
    "

    compile "libxcb" "$LIBXCB_FILE_NAME" "libxcb-$LIBXCB_VERSION" "$LIBXCB_BASE" "LIBXCB_CONFIGURE"
}
# }}}
# {{{ function compile_kbproto()
function compile_kbproto()
{
    is_installed kbproto "$KBPROTO_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    KBPROTO_CONFIGURE="
    ./configure --prefix=$KBPROTO_BASE
    "

    compile "kbproto" "$KBPROTO_FILE_NAME" "kbproto-$KBPROTO_VERSION" "$KBPROTO_BASE" "KBPROTO_CONFIGURE"
}
# }}}
# {{{ function compile_inputproto()
function compile_inputproto()
{
    is_installed inputproto "$INPUTPROTO_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    INPUTPROTO_CONFIGURE="
    ./configure --prefix=$INPUTPROTO_BASE
    "

    compile "inputproto" "$INPUTPROTO_FILE_NAME" "inputproto-$INPUTPROTO_VERSION" "$INPUTPROTO_BASE" "INPUTPROTO_CONFIGURE"
}
# }}}
# {{{ function compile_xextproto()
function compile_xextproto()
{
    is_installed xextproto "$XEXTPROTO_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    XEXTPROTO_CONFIGURE="
    ./configure --prefix=$XEXTPROTO_BASE
    "

    compile "xextproto" "$XEXTPROTO_FILE_NAME" "xextproto-$XEXTPROTO_VERSION" "$XEXTPROTO_BASE" "XEXTPROTO_CONFIGURE"
}
# }}}
# {{{ function compile_xtrans()
function compile_xtrans()
{
    is_installed xtrans "$XTRANS_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    XTRANS_CONFIGURE="
    ./configure --prefix=$XTRANS_BASE
    "

    compile "xtrans" "$XTRANS_FILE_NAME" "xtrans-$XTRANS_VERSION" "$XTRANS_BASE" "XTRANS_CONFIGURE"
}
# }}}
# {{{ function compile_xf86bigfontproto()
function compile_xf86bigfontproto()
{
    is_installed xf86bigfontproto "$XF86BIGFONTPROTO_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    XF86BIGFONTPROTO_CONFIGURE="
    ./configure --prefix=$XF86BIGFONTPROTO_BASE
    "

    compile "xf86bigfontproto" "$XF86BIGFONTPROTO_FILE_NAME" "xf86bigfontproto-$XF86BIGFONTPROTO_VERSION" "$XF86BIGFONTPROTO_BASE" "XF86BIGFONTPROTO_CONFIGURE"
}
# }}}
# {{{ function compile_libX11()
function compile_libX11()
{
    compile_macros
    compile_xcb_proto
    compile_libXau
    compile_libxcb
    compile_kbproto
    compile_inputproto
    compile_xextproto
    compile_xtrans
    compile_libpthread_stubs
    compile_xf86bigfontproto

    is_installed libX11 "$LIBX11_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBX11_CONFIGURE="
    ./configure --prefix=$LIBX11_BASE --enable-ipv6 --enable-loadable-i18n
    "
    # T_LC_ALL=$LC_ALL
    # LC_ALL=C ;

    compile "libX11" "$LIBX11_FILE_NAME" "libX11-$LIBX11_VERSION" "$LIBX11_BASE" "LIBX11_CONFIGURE"
    # LC_ALL=$T_LC_ALL
}
# }}}
# {{{ function compile_libXpm()
function compile_libXpm()
{
#    if [ "$OS_NAME" = 'Darwin' ];then
        compile_xproto
        compile_libX11
#    fi

    is_installed libXpm "$LIBXPM_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBXPM_CONFIGURE="
    ./configure --prefix=$LIBXPM_BASE
    "

    compile "libXpm" "$LIBXPM_FILE_NAME" "libXpm-$LIBXPM_VERSION" "$LIBXPM_BASE" "LIBXPM_CONFIGURE"
}
# }}}
# {{{ function compile_fontconfig()
function compile_fontconfig()
{
    compile_expat
    compile_freetype
    compile_libiconv
    compile_libxml2

    is_installed fontconfig "$FONTCONFIG_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    FONTCONFIG_CONFIGURE="
    ./configure --prefix=$FONTCONFIG_BASE --enable-iconv --enable-libxml2 \
                --with-libiconv=$LIBICONV_BASE \
                --with-expat=$EXPAT_BASE
    "

    compile "fontconfig" "$FONTCONFIG_FILE_NAME" "fontconfig-$FONTCONFIG_VERSION" "$FONTCONFIG_BASE" "FONTCONFIG_CONFIGURE"
}
# }}}
# {{{ function compile_gmp()
function compile_gmp()
{
    is_installed gmp "$GMP_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    GMP_CONFIGURE="
    ./configure --prefix=$GMP_BASE
    "

    compile "gmp" "$GMP_FILE_NAME" "gmp-$GMP_VERSION" "$GMP_BASE" "GMP_CONFIGURE"
}
# }}}
# {{{ function compile_imap()
function compile_imap()
{
    #yum install openssl openssl-devel
    #yum install kerberos-devel krb5-workstation
    #yum install pam pam-devel

    #compile_kerberos

    # 不支持openssl-1.1.0 及以上版本
    local OPENSSL_BASE=$OPENSSL_BASE
    local tmp_64=""
    if is_new_version $OPENSSL_VERSION "1.1.0" ; then
        if [ -f "/usr/lib64/pkgconfig/libssl.pc" ]; then
            local OPENSSL_BASE="/usr"
            local tmp_64="64"
        elif [ -d "/usr/local/Cellar/openssl" ]; then
            local tmp=`find /usr/local/Cellar/openssl -name libssl.pc|sed -n '1p'`;
            if [ ! -z "$tmp" -a -f "$tmp" ];then
                tmp=`dirname "$tmp"|xargs dirname`;
                tmp_64=$( basename $tmp|sed -n 's/lib//p')
                local OPENSSL_BASE=`dirname $tmp`;
            fi
        elif [ -f "/usr/lib/pkgconfig/libssl.pc" ]; then
            local OPENSSL_BASE="/usr"
            local tmp_64=""
        elif [ -f "/usr/local/lib64/pkgconfig/libssl.pc" ]; then
            local OPENSSL_BASE="/usr/local"
            local tmp_64="64"
        elif [ -f "/usr/local/lib/pkgconfig/libssl.pc" ]; then
            local OPENSSL_BASE="/usr/local"
            local tmp_64=""
        else
            echo "Please install OpenSSL(1.0.x) first." >&2
            exit 1;
        fi
    else
        compile_openssl
    fi

    IMAP_OPENSSL_BASE=$OPENSSL_BASE
    IMAP_TMP_64=$tmp_64

    is_installed imap "$IMAP_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    echo_build_start imap
    decompress $IMAP_FILE_NAME
    if [ "$?" != "0" ];then
        echo "decompress file error. FILE_NAME: $IMAP_FILE_NAME" >&2
        exit 1;
    fi

    cd imap-$IMAP_VERSION
    if [ "$?" != "0" ];then
        echo "dir [imap-${IMAP_VERSION}] is not exists." >&2
        exit 1;
    fi

    configure_imap_command

    cd ..
    rm -rf imap-${IMAP_VERSION}
}
# }}}
# {{{ function configure_imap_command()
function configure_imap_command()
{
    if is_new_version $OPENSSL_VERSION "1.1.0" ; then
        local OPENSSL_BASE=$IMAP_OPENSSL_BASE
        local tmp_64=$IMAP_TMP_64
    fi

    local os_type="lr5" #red hat linux 7.2以下
    if [ "$OS_NAME" = "Darwin" ]; then
        local os_type="osx"
    fi

    local tmp1_64=""
    if [ -f "/usr/lib64/libkrb5.so" ]; then
        KERBEROS_BASE="/usr"
        local tmp1_64="64"
    elif [ -d "/usr/local/Cellar/openssl" ]; then
        local tmp=`find /usr/local/Cellar/openssl -name libssl.pc|sed -n '1p'`;
        if [ ! -z "$tmp" -a -f "$tmp" ];then
            tmp=`dirname "$tmp"|xargs dirname`;
            tmp1_64=$( basename $tmp|sed -n 's/lib//p')
            KERBEROS_BASE=`dirname $tmp`;
        fi
    elif [ -f "/usr/lib/libkrb5.so" ]; then
        KERBEROS_BASE="/usr"
        local tmp1_64=""
    elif [ -f "/usr/local/lib64/libkrb5.so" ]; then
        KERBEROS_BASE="/usr/local"
        local tmp1_64="64"
    elif [ -f "/usr/local/lib/libkrb5.so" ]; then
        KERBEROS_BASE="/usr/local"
        local tmp1_64=""
    else
        echo "Please install krb5-devel krb5-libs first." >&2
        exit 1;
    fi


    #local old_str='SPECIALS="SSLINCLUDE=.* SSLLIB=.* SSLCERTS=.* SSLKEYS=.* GSSDIR=.*"'
    #local new_str="SPECIALS=\"SSLINCLUDE=${OPENSSL_BASE}/include/openssl SSLLIB=${OPENSSL_BASE}/lib${tmp_64} SSLCERTS=${OPENSSL_BASE}/ssl/certs SSLKEYS=${OPENSSL_BASE}/ssl/private GSSDIR=${KERBEROS_BASE}\""
    #sed -i "/lr5:/{n;n;n;s/$(sed_quote2 $old_str)/$(sed_quote2 $new_str)/}" ./Makefile

    #IP6=4
    #make lr5 PASSWDTYPE=std SSLTYPE=unix.nopwd EXTRACFLAGS=-fPIC IP=4
    if [ "$os_type" = "osx" -o "$os_type" = "lr5" ];then
        sed -i.bak$$ "/^${os_type}:/{n;n;n; \
                s/SSLINCLUDE=[^ \"]\{1,\}/SSLINCLUDE=$(sed_quote2 $OPENSSL_BASE/include/openssl )/; \
                s/SSLLIB=[^ \"]\{1,\}/SSLLIB=$(sed_quote2 $OPENSSL_BASE/lib${tmp_64} )/; \
                s/SSLCERTS=[^ \"]\{1,\}/SSLCERTS=$(sed_quote2 $OPENSSL_BASE/ssl/certs )/; \
                s/SSLKEYS=[^ \"]\{1,\}/SSLKEYS=$(sed_quote2 $OPENSSL_BASE/ssl/private )/; \
                s/GSSINCLUDE=[^ \"]\{1,\}/GSSINCLUDE=$(sed_quote2 $KERBEROS_BASE/include )/; \
                s/GSSLIB=[^ \"]\{1,\}/GSSLIB=$(sed_quote2 $KERBEROS_BASE/lib${tmp1_64} )/; \
                s/GSSDIR=[^ \"]\{1,\}/GSSDIR=$(sed_quote2 $KERBEROS_BASE )/; \
            }" ./Makefile
    fi
    echo "make command: "
    echo "make $os_type SSLINCLUDE=$OPENSSL_BASE/include/openssl SSLLIB=$OPENSSL_BASE/lib${tmp_64} SSLKEYS=$OPENSSL_BASE/ssl/private GSSDIR=$KERBEROS_BASE EXTRACFLAGS=-fPIC"

    make "$os_type" SSLINCLUDE=$OPENSSL_BASE/include/openssl SSLLIB=$OPENSSL_BASE/lib${tmp_64} SSLKEYS=$OPENSSL_BASE/ssl/private GSSDIR=$KERBEROS_BASE EXTRACFLAGS=-fPIC

    if [ "$?" != "0" ]; then
        echo "Install imap failed." >&2;
        exit 1;
    fi

    mkdir -p $IMAP_BASE/{lib,include} && \
    cp -pf c-client/*.h $IMAP_BASE/include/ && \
    cp -pf c-client/*.c $IMAP_BASE/lib/ && \
    cp -pf c-client/c-client.a $IMAP_BASE/lib/libc-client.a

    if [ "$?" != "0" ]; then
        echo "Install imap failed." >&2;
        exit 1;
    fi

}
# }}}
# {{{ function compile_kerberos()
function compile_kerberos()
{
    is_installed kerberos "$KERBEROS_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    KERBEROS_CONFIGURE="
    ./configure --prefix=$KERBEROS_BASE
    "

    compile "kerberos" "$KERBEROS_FILE_NAME" "krb5-$KERBEROS_VERSION/src" "$KERBEROS_BASE" "KERBEROS_CONFIGURE"
}
# }}}
# {{{ function compile_libmemcached()
function compile_libmemcached()
{
    is_installed libmemcached "$LIBMEMCACHED_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    # yum install cyrus-sasl-devel
    #gcc (GCC) 4.4.6 时没有问题
    #CC="gcc44" CXX="g++44"  \
    LIBMEMCACHED_CONFIGURE="
    configure_libmemcached_command
    "

    compile "libmemcached" "$LIBMEMCACHED_FILE_NAME" "libmemcached-$LIBMEMCACHED_VERSION" "$LIBMEMCACHED_BASE" "LIBMEMCACHED_CONFIGURE"
}
# }}}
# {{{ function compile_apr()
function compile_apr()
{
    is_installed apr "$APR_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    APR_CONFIGURE="
    ./configure --prefix=$APR_BASE
    "

    compile "apache-apr" "$APR_FILE_NAME" "apr-$APR_VERSION" "$APR_BASE" "APR_CONFIGURE"
}
# }}}
# {{{ function compile_apr_util()
function compile_apr_util()
{
    compile_openssl
    compile_libiconv
    compile_apr

    is_installed apr_util "$APR_UTIL_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    APR_UTIL_CONFIGURE="
    ./configure --prefix=$APR_UTIL_BASE \
                --with-openssl=$OPENSSL_BASE \
                --with-iconv=$LIBICONV_BASE \
                --with-crypto \
                --with-apr=$APR_BASE
    "

    compile "apache-apr-util" "$APR_UTIL_FILE_NAME" "apr-util-$APR_UTIL_VERSION" "$APR_UTIL_BASE" "APR_UTIL_CONFIGURE"
}
# }}}
# {{{ function compile_postgresql()
function compile_postgresql()
{
    is_installed postgresql "$POSTGRESQL_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    POSTGRESQL_CONFIGURE="
    ./configure --prefix=$POSTGRESQL_BASE
    "

    compile "postgresql" "$POSTGRESQL_FILE_NAME" "postgresql-$POSTGRESQL_VERSION" "$POSTGRESQL_BASE" "POSTGRESQL_CONFIGURE"
}
# }}}
# {{{ function compile_apache()
function compile_apache()
{
    compile_pcre
    compile_openssl
    compile_apr
    compile_apr_util

    is_installed apache "$APACHE_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    APACHE_CONFIGURE="
    ./configure --prefix=$APACHE_BASE \
                --sysconfdir=$APACHE_CONFIG_DIR \
                --with-mpm=worker \
                --enable-mods-static=few \
                --enable-so \
                --enable-rewrite \
                --enable-ssl \
                --with-ssl=$OPENSSL_BASE \
                --with-apr=$APR_BASE \
                --with-apr-util=$APR_UTIL_BASE \
                --with-pcre=$PCRE_BASE/bin/pcre-config
    "

    compile "apache" "$APACHE_FILE_NAME" "httpd-$APACHE_VERSION" "$APACHE_BASE" "APACHE_CONFIGURE"
}
# }}}
# {{{ function compile_nginx()
function compile_nginx()
{
    is_installed nginx "$NGINX_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    NGINX_CONFIGURE="
        configure_nginx_command
    "

    decompress $PCRE_FILE_NAME && decompress $ZLIB_FILE_NAME && decompress $OPENSSL_FILE_NAME
    if [ "$?" != "0" ];then
        # return 1;
        exit 1;
    fi

    compile "nginx" "$NGINX_FILE_NAME" "nginx-$NGINX_VERSION" "$NGINX_BASE" "NGINX_CONFIGURE"

    /bin/rm -rf pcre-$PCRE_VERSION
    /bin/rm -rf zlib-$ZLIB_VERSION
    /bin/rm -rf openssl-$OPENSSL_VERSION

    init_nginx_conf
}
# }}}
# {{{ function compile_rsyslog()
function compile_rsyslog()
{
    compile_liblogging
    compile_libgcrypt
    compile_libestr
    compile_libfastjson

    is_installed rsyslog "$RSYSLOG_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    PATH="$LIBGCRYPT_BASE/bin:$PATH"
    if test is_installed_mysql ; then
        PATH="$MYSQL_BASE/bin:$PATH"
    fi
    export PATH

    RSYSLOG_CONFIGURE="
    ./configure --prefix=$RSYSLOG_BASE \
                --enable-elasticsearch \
                $(is_installed_mysql && echo --enable-mysql ) \
                --enable-mail
                "
# No package 'uuid' found
# No package 'systemd' found
               # --enable-libgcrypt
#$( [ \"$OS_NAME\" = \"Darwin\" ] && echo --disable-uuid ) \

               # error: Net-SNMP is missing
               # --enable-snmp \

    compile "rsyslog" "$RSYSLOG_FILE_NAME" "rsyslog-$RSYSLOG_VERSION" "$RSYSLOG_BASE" "RSYSLOG_CONFIGURE"

    init_rsyslog_conf
}
# }}}
# {{{ function compile_liblogging()
function compile_liblogging()
{
    is_installed liblogging "$LIBLOGGING_BASE"
    if [ "$?" = "0" ];then
        return;
    fi


    LIBLOGGING_CONFIGURE="
    configure_liblogging_command
    "

    compile "liblogging" "$LIBLOGGING_FILE_NAME" "liblogging-$LIBLOGGING_VERSION" "$LIBLOGGING_BASE" "LIBLOGGING_CONFIGURE"
}
# }}}
# {{{ function configure_liblogging_command()
function configure_liblogging_command()
{
    local cmd="configure"
    if [ ! -f "$cmd" -a -f ./autogen.sh ]; then
        cmd="autogen.sh"
    fi
    ./${cmd} --prefix=$LIBLOGGING_BASE \
                --disable-man-pages
                #--enable-rfc3195
                #--enable-journal
                #--enable-stdlog
}
# }}}
# {{{ function compile_libgcrypt()
function compile_libgcrypt()
{
    compile_libgpg_error

    is_installed libgcrypt "$LIBGCRYPT_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBGCRYPT_CONFIGURE="
    ./configure --prefix=$LIBGCRYPT_BASE
    "

    compile "libgcrypt" "$LIBGCRYPT_FILE_NAME" "libgcrypt-$LIBGCRYPT_VERSION" "$LIBGCRYPT_BASE" "LIBGCRYPT_CONFIGURE"
}
# }}}
# {{{ function compile_libgpg_error()
function compile_libgpg_error()
{
    is_installed libgpg_error "$LIBGPG_ERROR_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBGPG_ERROR_CONFIGURE="
    ./configure --prefix=$LIBGPG_ERROR_BASE
    "

                #--enable-threads=posix
                #--with-libiconv-prefix=
                #--with-libintl-prefix=

    compile "libgpg-error" "$LIBGPG_ERROR_FILE_NAME" "libgpg-error-$LIBGPG_ERROR_VERSION" "$LIBGPG_ERROR_BASE" "LIBGPG_ERROR_CONFIGURE"
}
# }}}
# {{{ function compile_libestr()
function compile_libestr()
{
    is_installed libestr "$LIBESTR_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBESTR_CONFIGURE="
    ./configure --prefix=$LIBESTR_BASE
                "

    compile "libestr" "$LIBESTR_FILE_NAME" "libestr-$LIBESTR_VERSION" "$LIBESTR_BASE" "LIBESTR_CONFIGURE"

}
# }}}
# {{{ function compile_libgd()
function compile_libgd()
{
    compile_zlib
    compile_libpng
    compile_freetype
    compile_fontconfig
    compile_jpeg
    compile_libXpm

    is_installed libgd "$LIBGD_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    # CPPFLAGS="$(get_cppflags ${ZLIB_BASE}/include ${LIBPNG_BASE}/include ${LIBICONV_BASE}/include ${FREETYPE_BASE}/include ${FONTCONFIG_BASE}/include ${JPEG_BASE}/include $([ "$OS_NAME" = 'Darwin' ] && echo " $LIBX11_BASE/include") )" \
    # LDFLAGS="$(get_ldflags ${ZLIB_BASE}/lib ${LIBPNG_BASE}/lib ${LIBICONV_BASE}/lib ${FREETYPE_BASE}/lib ${FONTCONFIG_BASE}/lib ${JPEG_BASE}/lib $([ "$OS_NAME" = 'Darwin' ] && echo " $LIBX11_BASE/lib") )" \
    LIBGD_CONFIGURE="
    ./configure --prefix=$LIBGD_BASE --with-libiconv-prefix=$LIBICONV_BASE \
                --with-zlib=$ZLIB_BASE \
                --with-png=$LIBPNG_BASE \
                --with-freetype=$FREETYPE_BASE \
                --with-fontconfig=$FONTCONFIG_BASE \
                --with-xpm=$LIBXPM_BASE
                --with-jpeg=$JPEG_BASE
    "
                # --with-vpx=
                # --with-tiff=

    compile "libgd" "$LIBGD_FILE_NAME" "libgd-$LIBGD_VERSION" "$LIBGD_BASE" "LIBGD_CONFIGURE"
}
# }}}
# {{{ function compile_ImageMagick()
function compile_ImageMagick()
{
    compile_zlib
    compile_jpeg
    compile_libpng
    compile_freetype
    compile_fontconfig
    compile_libX11

    is_installed ImageMagick "$IMAGEMAGICK_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    IMAGEMAGICK_CONFIGURE="
    configure_ImageMagick_command
    "

    compile "ImageMagick" "$IMAGEMAGICK_FILE_NAME" "ImageMagick-$IMAGEMAGICK_VERSION" "$IMAGEMAGICK_BASE" "IMAGEMAGICK_CONFIGURE"
}
# }}}
# {{{ function compile_libsodium()
function compile_libsodium()
{
    is_installed libsodium "$LIBSODIUM_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBSODIUM_CONFIGURE="
        configure_libsodium_command
    "

    compile "libsodium" "$LIBSODIUM_FILE_NAME" "libsodium-$LIBSODIUM_VERSION" "$LIBSODIUM_BASE" "LIBSODIUM_CONFIGURE"
}
# }}}
# {{{ function compile_zeromq()
function compile_zeromq()
{
    if [ "$OS_NAME" != "Darwin" ]; then
        compile_libunwind
    fi
    # compile_libsodium

    is_installed zeromq "$ZEROMQ_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    ZEROMQ_CONFIGURE="
        ./configure --prefix=$ZEROMQ_BASE
    "

    compile "zeromq" "$ZEROMQ_FILE_NAME" "zeromq-$ZEROMQ_VERSION" "$ZEROMQ_BASE" "ZEROMQ_CONFIGURE"
}
# }}}
# {{{ function compile_hiredis()
function compile_hiredis()
{
    is_installed hiredis "$HIREDIS_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    HIREDIS_CONFIGURE="
        configure_hiredis_command
    "

    compile "hiredis" "$HIREDIS_FILE_NAME" "hiredis-$HIREDIS_VERSION" "$HIREDIS_BASE" "HIREDIS_CONFIGURE"
    if [ "$OS_NAME" = "Darwin" ];then
        repair_dynamic_shared_library $HIREDIS_BASE/lib "libhiredis*dylib"
    fi
}
# }}}
# {{{ function compile_libunwind()
function compile_libunwind()
{
    is_installed libunwind "$LIBUNWIND_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBUNWIND_CONFIGURE="
    ./configure --prefix=$LIBUNWIND_BASE \
                --enable-ptrace \
                --enable-block-signals \
                --enable-conservative-checks \
                --enable-minidebuginfo
    "
    compile "libunwind" "$LIBUNWIND_FILE_NAME" "libunwind-$LIBUNWIND_VERSION" "$LIBUNWIND_BASE" "LIBUNWIND_CONFIGURE"
    sed -i.bak '80s/UNW_INFO_FORMAT_IP_OFFSET,/UNW_INFO_FORMAT_IP_OFFSET/' $LIBUNWIND_BASE/include/libunwind-dynamic.h
}
# }}}
# {{{ function compile_rabbitmq_c()
function compile_rabbitmq_c()
{
    is_installed rabbitmq_c "$RABBITMQ_C_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    # compile_libsodium

    RABBITMQ_C_CONFIGURE="
    cmake -DCMAKE_INSTALL_PREFIX=$RABBITMQ_C_BASE
    "

    compile "rabbitmq-c" "$RABBITMQ_C_FILE_NAME" "rabbitmq-c-${RABBITMQ_C_VERSION}" "$RABBITMQ_C_BASE" "RABBITMQ_C_CONFIGURE"
}
# }}}
# {{{ function compile_php()
function compile_php()
{
    compile_openssl
    compile_sqlite
    compile_zlib
    compile_libxml2
    compile_gettext
    compile_libiconv
    compile_libmcrypt
    compile_curl
    compile_gmp
    compile_libgd
    compile_freetype
    compile_jpeg
    compile_libpng
    compile_libXpm

    is_installed php "$PHP_BASE"
    if [ "$?" = "0" ];then
        PHP_EXTENSION_DIR="$( find $PHP_LIB_DIR -name "no-debug-*" )"
        return;
    fi

    PHP_CONFIGURE="
        configure_php_command
    "

    compile "php" "$PHP_FILE_NAME" "php-$PHP_VERSION" "$PHP_BASE" "PHP_CONFIGURE" "after_php_make_install"

}
# }}}
# {{{ function after_php_make_install()
function after_php_make_install()
{
    mkdir -p $PHP_CONFIG_DIR $UPLOAD_TMP_DIR
    if [ "$?" != "0" ];then
        echo "mkdir error. commamnd: mkdir -p $PHP_CONFIG_DIR $UPLOAD_TMP_DIR" >&2
        return 1;
    fi

    cp php.ini* $PHP_CONFIG_DIR/
    if [ "$?" != "0" ];then
        echo "copy file error. commamnd: cp php.ini* $PHP_CONFIG_DIR/" >&2
        return 1;
    fi

    cat php.ini-production > $PHP_CONFIG_DIR/php.ini
    if [ "$?" != "0" ];then
        echo "copy file error. commamnd: cp php.ini-production > $PHP_CONFIG_DIR/php.ini" >&2
        return 1;
    fi

    cp $PHP_FPM_CONFIG_DIR/php-fpm.d/www.conf.default $PHP_FPM_CONFIG_DIR/php-fpm.d/www.conf
    if [ "$?" != "0" ];then
        echo "copy file error. commamnd: cp $PHP_FPM_CONFIG_DIR/php-fpm.d/www.conf.default $PHP_FPM_CONFIG_DIR/php-fpm.d/www.conf" >&2
        return 1;
    fi
    cp $PHP_FPM_CONFIG_DIR/php-fpm.conf.default $PHP_FPM_CONFIG_DIR/php-fpm.conf
    if [ "$?" != "0" ];then
        echo "copy file error. commamnd: cp $PHP_FPM_CONFIG_DIR/php-fpm.conf.default $PHP_FPM_CONFIG_DIR/php-fpm.conf" >&2
        return 1;
    fi

    PHP_EXTENSION_DIR="$( find $PHP_LIB_DIR -name "no-debug-*" )"

    init_php_ini
    init_php_fpm_ini

    #把opcache 写入php.ini
    write_zend_extension_info_to_php_ini "opcache.so"
}
# }}}
# {{{ function compile_php_extension_intl()
function compile_php_extension_intl()
{
    compile_icu

    is_installed_php_extension intl
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_INTL_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --enable-intl --with-icu-dir=$ICU_BASE
    "
    compile "php_extension_intl" "$PHP_FILE_NAME" "php-$PHP_VERSION/ext/intl/" "intl.so" "PHP_EXTENSION_INTL_CONFIGURE"
    if [ "$OS_NAME" = "Darwin" ];then
        for i in `find $PHP_LIB_DIR -name "no-debug-*"`;
        do
        {
            local file_name="${i}/intl.so"
            if [ -f "$file_name" ];then
                repair_dynamic_shared_library $file_name
            fi
        }
        done
    fi
}
# }}}
# {{{ function compile_php_extension_pdo_pgsql()
function compile_php_extension_pdo_pgsql()
{
    compile_postgresql

    is_installed_php_extension pdo_pgsql
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_PDO_PGSQL_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --with-pdo-pgsql=$POSTGRESQL_BASE
    "
    compile "php_extension_pdo_pgsql" "$PHP_FILE_NAME" "php-$PHP_VERSION/ext/pdo_pgsql/" "pdo_pgsql.so" "PHP_EXTENSION_PDO_PGSQL_CONFIGURE"
}
# }}}
# {{{ function compile_php_extension_apcu()
function compile_php_extension_apcu()
{
    is_installed_php_extension apcu
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_APCU_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --enable-apcu \
                --enable-apcu-clear-signal  --enable-apcu-spinlocks
    "
                # --enable-coverage
    compile "php_extension_apcu" "$APCU_FILE_NAME" "apcu-$APCU_VERSION" "apcu.so" "PHP_EXTENSION_APCU_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_apcu_bc()
function compile_php_extension_apcu_bc()
{
    compile_php_extension_apcu

    is_installed_php_extension apc
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_APCU_BC_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --enable-apc
    "
    compile "php_extension_apcu_bc" "$APCU_BC_FILE_NAME" "apcu_bc-$APCU_BC_VERSION" "apc.so" "PHP_EXTENSION_APCU_BC_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_yaf()
function compile_php_extension_yaf()
{
    is_installed_php_extension yaf
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_YAF_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --enable-yaf
    "
    compile "php_extension_yaf" "$YAF_FILE_NAME" "yaf-$YAF_VERSION" "yaf.so" "PHP_EXTENSION_YAF_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_phalcon()
function compile_php_extension_phalcon()
{
    compile_php

    is_installed_php_extension phalcon
    if [ "$?" = "0" ];then
        return;
    fi

    #PHP_VERSION=`$PHP_BASE/bin/php-config --version`

    if echo "$HOST_TYPE"|grep -q x86_64 ; then
        local tmp_str="64"
    else
        local tmp_str="32"
    fi
    local tmp_dir="cphalcon-${PHALCON_VERSION}/build/php${PHP_VERSION%%.*}/${tmp_str}bits"


    PHP_EXTENSION_PHALCON_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --enable-phalcon
    "

    compile "php_extension_phalcon" "$PHALCON_FILE_NAME" "$tmp_dir" "phalcon.so" "PHP_EXTENSION_PHALCON_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_xdebug()
function compile_php_extension_xdebug()
{
    is_installed_php_extension xdebug
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_XDEBUG_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --enable-xdebug
    "
    compile "php_extension_xdebug" "$XDEBUG_FILE_NAME" "xdebug-$XDEBUG_VERSION" "xdebug.so" "PHP_EXTENSION_XDEBUG_CONFIGURE"
    sed -i.bak.$$ 's/^\(extension=xdebug\.so\)$/zend_\1/' $php_ini

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_raphf()
function compile_php_extension_raphf()
{
    is_installed_php_extension raphf
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_RAPHF_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --enable-raphf
    "
    compile "php_extension_raphf" "$RAPHF_FILE_NAME" "raphf-$RAPHF_VERSION" "raphf.so" "PHP_EXTENSION_RAPHF_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_propro()
function compile_php_extension_propro()
{
    is_installed_php_extension propro
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_PROPRO_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --enable-propro
    "
    compile "php_extension_propro" "$PROPRO_FILE_NAME" "propro-$PROPRO_VERSION" "propro.so" "PHP_EXTENSION_PROPRO_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_pecl_http()
function compile_php_extension_pecl_http()
{
    is_installed_php_extension http
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_PECL_HTTP_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --with-http \
                --with-http-zlib-dir=$ZLIB_BASE \
                --with-http-libcurl-dir=$CURL_BASE \
                --with-http-libevent-dir=$LIBEVENT_BASE
    "
                # --with-http-libidn-dir=

    compile "php_extension_pecl_http" "$PECL_HTTP_FILE_NAME" "pecl_http-$PECL_HTTP_VERSION" "http.so" "PHP_EXTENSION_PECL_HTTP_CONFIGURE"

    /bin/rm -rf package.xml

    if [ "$OS_NAME" = "Darwin" ];then
        for i in `find $PHP_LIB_DIR -name "no-debug-*"`;
        do
        {
            local file_name="${i}/http.so"
            if [ -f "$file_name" ];then
                repair_dynamic_shared_library $file_name
            fi
        }
        done
    fi
}
# }}}
# {{{ function compile_php_extension_amqp()
function compile_php_extension_amqp()
{
    compile_rabbitmq_c

    is_installed_php_extension amqp
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_AMQP_CONFIGURE="
    configure_php_amqp_command
    "

    compile "php_extension_amqp" "$AMQP_FILE_NAME" "amqp-$AMQP_VERSION" "amqp.so" "PHP_EXTENSION_AMQP_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_mailparse()
function compile_php_extension_mailparse()
{
    is_installed_php_extension mailparse
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_MAILPARSE_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --enable-mailparse
    "

    compile "php_extension_mailparse" "$MAILPARSE_FILE_NAME" "mailparse-$MAILPARSE_VERSION" "mailparse.so" "PHP_EXTENSION_MAILPARSE_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_redis()
function compile_php_extension_redis()
{
    is_installed_php_extension redis
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_REDIS_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --enable-redis
    "
                # --enable-redis-igbinary

    compile "php_extension_redis" "$PHP_REDIS_FILE_NAME" "redis-$PHP_REDIS_VERSION" "redis.so" "PHP_EXTENSION_REDIS_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_gearman()
function compile_php_extension_gearman()
{
    compile_gearmand

    is_installed_php_extension gearman
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_GEARMAN_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --with-gearman=$GEARMAND_BASE
    "

    compile "php_extension_gearman" "$PHP_GEARMAN_FILE_NAME" "${PHP_GEARMAN_FILE_NAME%-*}-${PHP_GEARMAN_VERSION}" "gearman.so" "PHP_EXTENSION_GEARMAN_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_mongodb()
function compile_php_extension_mongodb()
{
    compile_openssl
    compile_pcre

    is_installed_php_extension mongodb
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_MONGODB_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --enable-mongodb --with-openssl-dir=$OPENSSL_BASE --with-pcre-dir=$PCRE_BASE
    "
                # --with-libbson --with-libmongoc

    compile "php_extension_mongodb" "$PHP_MONGODB_FILE_NAME" "mongodb-$PHP_MONGODB_VERSION" "mongodb.so" "PHP_EXTENSION_MONGODB_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_solr()
function compile_php_extension_solr()
{
    compile_curl
    compile_libxml2

    is_installed_php_extension solr
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_SOLR_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --enable-solr \
                --with-curl=$CURL_BASE \
                --with-libxml-dir=$LIBXML2_BASE
    "

    compile "php_extension_solr" "$SOLR_FILE_NAME" "solr-$SOLR_VERSION" "solr.so" "PHP_EXTENSION_SOLR_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_memcached()
function compile_php_extension_memcached()
{
    compile_zlib
    compile_libmemcached

    is_installed_php_extension memcached
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_MEMCACHED_CONFIGURE="
    configure_php_ext_memcached_command
    "

    compile "php_extension_memcached" "$PHP_MEMCACHED_FILE_NAME" "memcached-$PHP_MEMCACHED_VERSION" "memcached.so" "PHP_EXTENSION_MEMCACHED_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function configure_php_ext_memcached_command()
function configure_php_ext_memcached_command()
{
    # yum install cyrus-sasl-devel or --disable-memcached-sasl
    CPPFLAGS="$(get_cppflags $OPENSSL_BASE/include)" LDFLAGS="$(get_ldflags $OPENSSL_BASE/lib)" \
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --with-libmemcached-dir=$LIBMEMCACHED_BASE \
                --enable-memcached-json \
                --with-zlib-dir=$ZLIB_BASE

                # --enable-memcached-igbinary
                # --enable-memcached
                # --enable-memcached-protocol
                # --disable-memcached-sasl
                # --enable-memcached-msgpack

}
# }}}
# {{{ function compile_php_extension_pthreads()
function compile_php_extension_pthreads()
{
    is_installed_php_extension pthreads
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_PTHREADS_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config
    "
    # --enable-pthreads
    # --with-pthreads-sanitize --with-pthreads-dmalloc

    compile "php_extension_pthreads" "$PTHREADS_FILE_NAME" "pthreads-$PTHREADS_VERSION" "pthreads.so" "PHP_EXTENSION_PTHREADS_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_swoole()
function compile_php_extension_swoole()
{
    compile_openssl
    compile_pcre
    compile_hiredis

    is_installed_php_extension swoole
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_SWOOLE_CONFIGURE="
    configure_php_swoole_command
    "

    compile "php_extension_swoole" "$SWOOLE_FILE_NAME" "swoole-$SWOOLE_VERSION" "swoole.so" "PHP_EXTENSION_SWOOLE_CONFIGURE"

    /bin/rm -rf package.xml
    if [ -f "$curr_dir/swoole_test.php" ];then
        $PHP_BASE/bin/php $curr_dir/swoole_test.php
        if [ "$?" != 0 ];then
            echo "ERROR: swoole not use pcre." >&2
            return 1;
        fi
    fi
}
# }}}
# {{{ function compile_php_extension_qrencode()
function compile_php_extension_qrencode()
{
    compile_qrencode

    is_installed_php_extension qrencode
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_QRENCODE_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --with-qrencode=$LIBQRENCODE_BASE
    "

    # $PHP_BASE/bin/phpize --clean
    compile "php_extension_qrencode" "$QRENCODE_FILE_NAME" "qrencode-$QRENCODE_VERSION" "qrencode.so" "PHP_EXTENSION_QRENCODE_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_dio()
function compile_php_extension_dio()
{
    is_installed_php_extension dio
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_DIO_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config
    "

    compile "php_extension_dio" "$DIO_FILE_NAME" "dio-$DIO_VERSION" "dio.so" "PHP_EXTENSION_DIO_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_event()
function compile_php_extension_event()
{
    compile_openssl
    compile_libevent

    is_installed_php_extension event
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_EVENT_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --with-event-libevent-dir=$LIBEVENT_BASE \
                --enable-event-sockets --with-event-pthreads \
                --with-openssl-dir=$OPENSSL_BASE --with-event-openssl
    "

    compile "php_extension_event" "$EVENT_FILE_NAME" "event-$EVENT_VERSION" "event.so" "PHP_EXTENSION_EVENT_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_libevent()
function compile_php_extension_libevent()
{
    compile_libevent

    is_installed_php_extension libevent
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_LIBEVENT_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --with-libevent=$LIBEVENT_BASE
    "

    compile "php_extension_libevent" "$PHP_LIBEVENT_FILE_NAME" "libevent-$PHP_LIBEVENT_VERSION" "libevent.so" "PHP_EXTENSION_LIBEVENT_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_imagick()
function compile_php_extension_imagick()
{
    compile_ImageMagick

    is_installed_php_extension imagick
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_IMAGICK_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --with-imagick=$IMAGEMAGICK_BASE
    "

    compile "php_extension_imagick" "$IMAGICK_FILE_NAME" "imagick-$IMAGICK_VERSION" "imagick.so" "PHP_EXTENSION_IMAGICK_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_zeromq()
function compile_php_extension_zeromq()
{
    compile_zeromq

    is_installed_php_extension zmq
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_ZEROMQ_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --with-zmq=$ZEROMQ_BASE
    "
                #--enable-zmq-pthreads
                # --with-czmq=

    compile "php_extension_zeromq" "$PHP_ZMQ_FILE_NAME" "php-zmq-$PHP_ZMQ_VERSION" "zmq.so" "PHP_EXTENSION_ZEROMQ_CONFIGURE"
}
# }}}
# {{{ function compile_php_extension_libsodium()
function compile_php_extension_libsodium()
{
    compile_libsodium

    is_installed_php_extension libsodium
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_LIBSODIUM_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --with-libsodium=$LIBSODIUM_BASE
    "

    compile "php_extension_libsodium" "$PHP_LIBSODIUM_FILE_NAME" "libsodium-$PHP_LIBSODIUM_VERSION" "libsodium.so" "PHP_EXTENSION_LIBSODIUM_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_tidy()
function compile_php_extension_tidy()
{
    compile_tidy

    is_installed_php_extension tidy
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_TIDY_CONFIGURE="
    configure_php_tidy_command
    "

    compile "php_extension_tidy" "$PHP_FILE_NAME" "php-${PHP_VERSION}/ext/tidy" "tidy.so" "PHP_EXTENSION_TIDY_CONFIGURE"

    /bin/rm -rf package.xml
    if [ "$OS_NAME" = "Darwin" ];then
        for i in `find $PHP_LIB_DIR -name "no-debug-*"`;
        do
        {
            local file_name="${i}/tidy.so"
            if [ -f "$file_name" ];then
                repair_dynamic_shared_library $file_name
            fi
        }
        done
    fi
}
# }}}
# {{{ function compile_php_extension_imap()
function compile_php_extension_imap()
{
    #compile_kerberos
    compile_imap
    #yum install -y libc-client-devel libc-client
    compile_openssl

    is_installed_php_extension imap
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_IMAP_CONFIGURE="
        configure_php_ext_imap_command
    "

    compile "php_extension_imap" "$PHP_FILE_NAME" "php-${PHP_VERSION}/ext/imap" "imap.so" "PHP_EXTENSION_IMAP_CONFIGURE"

    /bin/rm -rf package.xml
    if [ "$OS_NAME" = "Darwin" ];then
        repair_dynamic_shared_library $PHP_EXTENSION_DIR/imap.so
    fi
}
# }}}
# {{{ function configure_php_ext_imap_command()
function configure_php_ext_imap_command()
{
    if is_new_version $OPENSSL_VERSION "1.1.0" ; then
        local OPENSSL_BASE=$IMAP_OPENSSL_BASE
        local tmp_64=$IMAP_TMP_64
    fi
    if ! is_installed_imap && echo "$HOST_TYPE"|grep -q x86_64 ; then
        sed -i.bak$$ 's/str="$IMAP_DIR\/$PHP_LIBDIR/str="$IMAP_DIR\/${PHP_LIBDIR}64/' configure
    fi
    if [ ! -z "$tmp_64" ];then
        sed -i.bak$$ 's/$PHP_LIBDIR\/libssl\./${PHP_LIBDIR}64\/libssl./g' ./configure
    fi

    local tmp_str=`find /usr/lib*/pkgconfig/ -name krb5.pc|sed -n '1p'`
    if [ ! -z "$tmp_str" ] && echo $tmp_str|grep -q 'lib64' ;then
        sed -i.bak$$ 's/$PHP_LIBDIR\/libkrb5\./${PHP_LIBDIR}64\/libkrb5./g' ./configure
    fi

    #which krb5-config

     #if test -r $i/${PHP_LIBDIR}64/libssl.a -o -r $i/${PHP_LIBDIR}64/libssl.$SHLIB_SUFFIX_NAME; then
     #OPENSSL_LIBDIR=$i/${PHP_LIBDIR}64

    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --with-imap$(is_installed_imap && echo "=$IMAP_BASE" ) \
                --with-kerberos=$KERBEROS_BASE \
                --with-imap-ssl=$OPENSSL_BASE

    # CPPFLAGS="$(get_cppflags $OPENSSL_BASE/include)" LDFLAGS="$(get_ldflags $OPENSSL_BASE/lib)" \
                # --with-libdir=lib64 \
}
# }}}
# {{{ function compile_php_extension_sphinx()
function compile_php_extension_sphinx()
{
    compile_sphinxclient

    is_installed_php_extension sphinx
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_SPHINX_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --with-sphinx=$SPHINX_CLIENT_BASE
    "

    compile "php_extension_sphinx" "$PHP_SPHINX_FILE_NAME" "pecl-search_engine-sphinx-${PHP_SPHINX_VERSION}" "sphinx.so" "PHP_EXTENSION_SPHINX_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_mysql()
function compile_mysql()
{
    compile_openssl

    is_installed mysql "$MYSQL_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    echo_build_start mysql

    decompress $MYSQL_FILE_NAME
    if [ "$?" != "0" ];then
        exit;
    fi

    local boost_cmake_file="mysql-$MYSQL_VERSION/cmake/boost.cmake"
    if [ ! -f "$boost_cmake_file" ];then
        echo "Warning: Can't find file: $boost_cmake_file" >&2
        exit 1;
    fi
    local version=`sed -n 's/^SET(BOOST_PACKAGE_NAME "boost_\(.\{1,\}\)")$/\1/p' $boost_cmake_file`
    if [ "$version" != "$BOOST_VERSION" ];then
        echo "Warning: BOOST VERSION ERROR: need $version, give $BOOST_VERSION" >&2

        local old_version=$BOOST_VERSION
        local old_file=$BOOST_FILE_NAME

        BOOST_VERSION=$version
        BOOST_FILE_NAME="boost_${BOOST_VERSION}.tar.bz2"
        wget_lib_boost
        if [ "$wget_fail" = "1" ];then
            exit 1;
        fi

        BOOST_VERSION=$old_version
        BOOST_FILE_NAME=$old_file

        local BOOST_VERSION=$version
        local BOOST_FILE_NAME="boost_${BOOST_VERSION}.tar.bz2"
    fi

    decompress $BOOST_FILE_NAME
    if [ "$?" != "0" ];then
        exit 1;
    fi

    mysql_install=mysql_install
    mkdir $mysql_install
    cd $mysql_install

    #sudo yum install glibc-static*
    #sudo yum install ncurses-devel ncurses
    cmake ../mysql-$MYSQL_VERSION -DCMAKE_INSTALL_PREFIX=$MYSQL_BASE \
                                  -DSYSCONFDIR=$MYSQL_CONFIG_DIR \
                                  -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci \
                                  -DWITH_SSL=bundled \
                                  -DWITH_BOOST=../boost_${BOOST_VERSION}/ \
                                  -DWITH_ZLIB=bundled \
                                  -DINSTALL_MYSQLTESTDIR=

                                  # -DWITH_SSL=$OPENSSL_BASE \  # OPENSSL_VERSIOn > 1.1时，编译不过去
                                  # -DWITH_INNOBASE_STORAGE_ENGINE=1 \
                                  # -DWITH_PARTITION_STORAGE_ENGINE=1
                                  # -DWITH_INNODB_MEMCACHED=1 \ mac系统下编译不过去，报错
                                  # -DWITH_EXTRA_CHARSET:STRING=utf8,gbk \
                                  # -DWITH_MYISAM_STORAGE_ENGINE=1 \
                                  # -DWITH_MEMORY_STORAGE_ENGINE=1 \
                                  # -DWITH_READLINE=1 \
                                  # -DENABLED_LOCAL_INFILE=1 \                      #允许从本地导入数据
    make_run "$?/mysql"
    if [ "$?" != "0" ];then
        exit 1;
    fi

    cd ..
    /bin/rm -rf mysql-$MYSQL_VERSION
    /bin/rm -rf $mysql_install
    /bin/rm -rf boost_$BOOST_VERSION

    mkdir -p $MYSQL_CONFIG_DIR
    cp $curr_dir/my.cnf $mysql_cnf
    if [ "$?" != "0" ];then
        exit;
    fi

    init_mysql_cnf
}
# }}}}
# {{{ function compile_qrencode()
function compile_qrencode()
{
    compile_libiconv

    is_installed qrencode "$LIBQRENCODE_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    QRENCODE_CONFIGURE="
    ./configure --prefix=$LIBQRENCODE_BASE \
                --with-libiconv-prefix=$LIBICONV_BASE
    "

    compile "qrencode" "$LIBQRENCODE_FILE_NAME" "qrencode-$LIBQRENCODE_VERSION" "$LIBQRENCODE_BASE" "QRENCODE_CONFIGURE"
}
# }}}
# {{{ function compile_nasm()
function compile_nasm()
{
    is_installed nasm "$NASM_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    NASM_CONFIGURE="
    ./configure --prefix=$NASM_BASE
    "

    compile "nasm" "$NASM_FILE_NAME" "nasm-$NASM_VERSION" "$NASM_BASE" "NASM_CONFIGURE"
}
# }}}
# {{{ function compile_libjpeg()
function compile_libjpeg()
{
    compile_nasm

    is_installed libjpeg "$LIBJPEG_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBJPEG_CONFIGURE="
    ./configure --prefix=$LIBJPEG_BASE
    "

    compile "libjpeg" "$LIBJPEG_FILE_NAME" "libjpeg-turbo-$LIBJPEG_VERSION" "$LIBJPEG_BASE" "LIBJPEG_CONFIGURE"
}
# }}}
# {{{ function compile_pixman()
function compile_pixman()
{
    is_installed pixman "$PIXMAN_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    PIXMAN_CONFIGURE="
    ./configure --prefix=$PIXMAN_BASE
    "

    compile "pixman" "$PIXMAN_FILE_NAME" "pixman-$PIXMAN_VERSION" "$PIXMAN_BASE" "PIXMAN_CONFIGURE"
}
# }}}
# {{{ function compile_libmaxminddb()
function compile_libmaxminddb()
{
    is_installed libmaxminddb "$LIBMAXMINDDB_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBMAXMINDDB_CONFIGURE="
    configure_libmaxminddb_command
    "

    compile "libmaxminddb" "$LIBMAXMINDDB_FILE_NAME" "libmaxminddb-$LIBMAXMINDDB_VERSION" "$LIBMAXMINDDB_BASE" "LIBMAXMINDDB_CONFIGURE"
}
# }}}
# {{{ function compile_php_extension_maxminddb()
function compile_php_extension_maxminddb()
{
    compile_libmaxminddb

    is_installed_php_extension maxminddb
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_MAXMINDDB_CONFIGURE="
    configure_php_maxminddb_command
    "
    local ext_dir="MaxMind-DB-Reader-php-$MAXMIND_DB_READER_PHP_VERSION/ext"
    local file_name="$MAXMIND_DB_READER_PHP_FILE_NAME"

    compile "php_extension_maxminddb" "$file_name" "$ext_dir" "maxminddb.so" "PHP_EXTENSION_MAXMINDDB_CONFIGURE" "after_php_extension_maxminddb_make_install"
}
# }}}
# {{{ function after_php_extension_maxminddb_make_install()
function after_php_extension_maxminddb_make_install()
{
    mkdir -p $BASE_DIR/inc/MaxMind
    if [ "$?" != "0" ];then
        echo "mkdir faild. command: mkdir -p $BASE_DIR/inc/MaxMind" >&2
        return 1;
    fi
    cp -r ../src/MaxMind/* $BASE_DIR/inc/MaxMind
    if [ "$?" != "0" ];then
        echo " copy file faild. command: cp -r ../src/MaxMind/* $BASE_DIR/inc/MaxMind" >&2
        return 1;
    fi
}
# }}}
# {{{ function compile_geoipupdate()
function compile_geoipupdate()
{
    is_installed geoipupdate "$GEOIPUPDATE_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    GEOIPUPDATE_CONFIGURE="
    configure_geoipupdate_command
    "

    compile "geoipupdate" "$GEOIPUPDATE_FILE_NAME" "geoipupdate-$GEOIPUPDATE_VERSION" "$GEOIPUPDATE_BASE" "GEOIPUPDATE_CONFIGURE"
    sudo sed -i.bak.$$ "s/^# DatabaseDirectory .*$/DatabaseDirectory $(sed_quote2 $GEOIP2_DATA_DIR)/" $BASE_DIR/etc/GeoIP.conf
    if [ "$?" != "0" ]; then
        echo "mod $BASE_DIR/etc/GeoIP.conf faild." >&2;
        return 1;
    fi
}
# }}}
# }}}
# {{{ function cp_GeoLite2_data()
function cp_GeoLite2_data()
{
    if [ -z "$GEOIP2_DATA_DIR" ];then
        echo "variable GEOIP2_DATA_DIR is nod exists." >&2
        return 1;
    fi

    mkdir -p $GEOIP2_DATA_DIR

    if [ ! -f "$GEOLITE2_CITY_MMDB_FILE_NAME" ] || [ ! -f "$GEOLITE2_COUNTRY_MMDB_FILE_NAME" ];then
        echo "file [${GEOLITE2_CITY_MMDB_FILE_NAME}] or [${GEOLITE2_COUNTRY_MMDB_FILE_NAME}]  not exists." >&2
        return 1;
    fi 

    if [ ! -f  "$GEOIP2_DATA_DIR/GeoLite2-City.mmdb" ];then
        gunzip -c $GEOLITE2_CITY_MMDB_FILE_NAME > $GEOIP2_DATA_DIR/GeoLite2-City.mmdb
        if [ "$?" != "0" ];then
            echo "gunzip faild. file: $GEOLITE2_CITY_MMDB_FILE_NAME" >&2
            return 1;
        fi
    fi

    if [ ! -f  "$GEOIP2_DATA_DIR/GeoLite2-Country.mmdb" ];then
        gunzip -c $GEOLITE2_COUNTRY_MMDB_FILE_NAME > $GEOIP2_DATA_DIR/GeoLite2-Country.mmdb
        if [ "$?" != "0" ];then
            echo "gunzip faild. file: $GEOLITE2_COUNTRY_MMDB_FILE_NAME" >&2
            return 1;
        fi
    fi
    return 0;
}
# }}}
# {{{ function install_web_service_common_php()
function install_web_service_common_php()
{
    echo_build_start "install_web_service_common_php"
    decompress $WEB_SERVICE_COMMON_PHP_FILE_NAME
    if [ "$?" != "0" ];then
        echo "decompress file error. file_name: $WEB_SERVICE_COMMON_PHP_FILE_NAME" >&2
        # return 1;
        exit 1;
    fi

    mkdir -p $BASE_DIR/inc/MaxMind
    if [ "$?" != "0" ];then
        echo "mkdir faild. command: mkdir -p $BASE_DIR/inc/MaxMind" >&2
        # return 1;
        exit 1;
    fi

    cp -r web-service-common-php-$WEB_SERVICE_COMMON_PHP_VERSION/src/* $BASE_DIR/inc/MaxMind
    if [ "$?" != "0" ];then
        echo "copy file faild. command: cp -r $web-service-common-php-$WEB_SERVICE_COMMON_PHP_VERSION/src/* $BASE_DIR/inc/MaxMind" >&2
        # return 1;
        exit 1;
    fi

    rm -rf web-service-common-php-$WEB_SERVICE_COMMON_PHP_VERSION
    if [ "$?" != "0" ];then
        echo "delete dir faild. command: rm -rf web-service-common-php-$WEB_SERVICE_COMMON_PHP_VERSION" >&2
        # return 1;
        exit 1;
    fi

}
# }}}
# {{{ function install_geoip2_php()
function install_geoip2_php()
{
    echo_build_start "install_geoip2_php"
    decompress $GEOIP2_PHP_FILE_NAME
    if [ "$?" != "0" ];then
        echo "decompress file error. file_name: $GEOIP2_PHP_FILE_NAME" >&2
        # return 1;
        exit 1;
    fi

    mkdir -p $BASE_DIR/inc/GeoIp2
    if [ "$?" != "0" ];then
        echo "mkdir faild. command: mkdir -p $BASE_DIR/inc/GeoIp2" >&2
        # return 1;
        exit 1;
    fi

    cp -r GeoIP2-php-$GEOIP2_PHP_VERSION/src/* $BASE_DIR/inc/GeoIp2/
    if [ "$?" != "0" ];then
        echo "copy file faild. command: cp -r GeoIP2-php-$GEOIP2_PHP_VERSION/src/* $BASE_DIR/inc/GeoIp2/" >&2
        # return 1;
        exit 1;
    fi

    rm -rf GeoIP2-php-$GEOIP2_PHP_VERSION
    if [ "$?" != "0" ];then
        echo "delete dir faild. command: GeoIP2-php-$GEOIP2_PHP_VERSION" >&2
        # return 1;
        exit 1;
    fi
}
# }}}
# {{{ function compile_zendFramework()
function compile_zendFramework()
{
#    is_installed zendFramework
#    if [ "$?" = "0" ];then
#        return;
#    fi

    echo_build_start ZendFramework
    decompress $ZEND_FILE_NAME
    mkdir -p $ZEND_BASE
    cp -r ZendFramework-$ZEND_VERSION/library/* $ZEND_BASE

    /bin/rm -rf ZendFramework-$ZEND_VERSION
}
# }}}
# {{{ function compile_smarty()
function compile_smarty()
{
#    is_installed smarty
#    if [ "$?" = "0" ];then
#        return;
#    fi

    echo_build_start smarty
    decompress $SMARTY_FILE_NAME
    mkdir -p $SMARTY_BASE
    cp -r smarty-$SMARTY_VERSION/libs/* $SMARTY_BASE
    /bin/rm -rf smarty-$SMARTY_VERSION
}
# }}}
# {{{ function compile_composer()
function compile_composer()
{

    echo_build_start composer
    decompress $COMPOSER_FILE_NAME
    mkdir -p $COMPOSER_BASE
    cp -r composer-$COMPOSER_VERSION/src/Composer $COMPOSER_BASE/
    cp composer-$COMPOSER_VERSION/bin/* $BIN_DIR/

    # 需要sed 处理bin/目录下的文件中包含文件的行

    /bin/rm -rf composer-$COMPOSER_VERSION
}
# }}}
# {{{ function compile_ckeditor()
function compile_ckeditor()
{
#    is_installed ckeditor
#    if [ "$?" = "0" ];then
#        return;
#    fi

    echo_build_start ckeditor
    decompress $CKEDITOR_FILE_NAME

    mkdir -p $CKEDITOR_BASE
    cd ckeditor
    cp -r adapters $CKEDITOR_BASE/adapters
    cp ckeditor.js $CKEDITOR_BASE/
    cp contents.css $CKEDITOR_BASE/
    cp styles.js $CKEDITOR_BASE/
    cp config.js $CKEDITOR_BASE/config.js.bak
    #cp -r images $CKEDITOR_BASE/images
    cp -r lang $CKEDITOR_BASE/lang
    cp -r skins $CKEDITOR_BASE/skins
    cp -r plugins $CKEDITOR_BASE/plugins
    #mv $CKEDITOR_BASE/lang/zh-cn.js $CKEDITOR_BASE/lang/zh-cn.js.bak
    #mv $CKEDITOR_BASE/skins/kama/dialog.css $CKEDITOR_BASE/skins/kama/dialog.css.bak
    cd ..

    /bin/rm -rf ckeditor
}
# }}}
# {{{ function compile_jquery()
function compile_jquery()
{
#    is_installed jquery
#    if [ "$?" = "0" ];then
#        return;
#    fi

    echo_build_start jquery
    mkdir -p $JQUERY_BASE
    cp jquery-$JQUERY_VERSION.js $JQUERY_BASE/jquery.js


}
# }}}
# {{{ function compile_famous()
function compile_famous()
{
    echo_build_start famous
    mkdir -p $FAMOUS_BASE

    decompress ${FAMOUS_FILE_NAME}
    if [ "$?" != "0" ];then
        # return 1;
        exit 1;
    fi

    famous.css            famous-global.js      famous-global.min.js  famous.js             famous.min.js
    cp famous-${FAMOUS_VERSION}/dist/*.min.js $FAMOUS_BASE/
    cp famous-${FAMOUS_VERSION}/dist/*.css $CSS_BASE/
    cd famous-0.3.5
    cp dist/famous

    famous.css            famous-global.js      famous-global.min.js  famous.js             famous.min.js





     famous-angular-0.5.2]# ls dist/
     famous-angular.css  famous-angular.js  famous-angular.min.css  famous-angular.min.js


}
# }}}
# {{{ configure command functions
# {{{ configure_geoipupdate_command()
configure_geoipupdate_command()
{
    CPPFLAGS="$(get_cppflags $CURL_BASE/include)" LDFLAGS="$(get_ldflags $CURL_BASE/lib)" \
    ./configure --prefix=$GEOIPUPDATE_BASE --sysconfdir=$BASE_DIR/etc
}
# }}}
# {{{ configure_fontforge_command()
configure_fontforge_command()
{
    local autoconf1=""
    local curr_version=""
    local minimum_version="2.68";

    local tmp_arr=( "/usr/bin/autoconf" "/usr/local/bin/autoconf" "`which autoconf`" );
    local i=""

    if [ "$OS_NAME" != "Darwin" ];then
        for i in ${tmp_arr[@]}; do
        {
            if [ -f "$i" ];then
                local curr_version=`$i --version|sed -n '1p'|awk '{print $NF;}'`;
                is_new_version "$curr_version" "$minimum_version"
                if [ "$?" = "0" ]; then
                    autoconf1=$i;
                    break;
                fi
            fi
        }
        done
    fi

    local old_path="$PATH"

    if [ ! -z "$autoconf1" -a "$autoconf1" != "`which autoconf`" ];then
        PATH="${autoconf1%/*}:$PATH"
    fi

    export PATH="$PATH" 

    ./bootstrap && \
    LIBPNG_CFLAGS="$(get_cppflags $LIBPNG_BASE/include /usr/local/include )" \
    LIBPNG_LIBS="$(get_ldflags $LIBPNG_BASE/lib /usr//local/lib )" \
    ./configure --prefix=$FONTFORGE_BASE \
                --disable-python-scripting \
                --disable-python-extension \
                --enable-extra-encodings \
                --without-x
    local flag=$?
    #export PATH="$old_path"
    return $flag
}
# }}}
# {{{ configure_curl_command()
configure_curl_command()
{
    ./configure --prefix=$CURL_BASE \
                --with-zlib=$ZLIB_BASE \
                --with-ssl=$OPENSSL_BASE
}
# }}}
# {{{ configure_harfbuzz_command()
configure_harfbuzz_command()
{
    CPPFLAGS="$(get_cppflags ${$ICU_BASE}/include ${FREETYPE_BASE}/include)" \
    LDFLAGS="$(get_ldflags ${ICU_BASE}/lib ${FREETYPE_BASE}/lib)" \
    ./configure --prefix=$HARFBUZZ_BASE
}
# }}}
# {{{ configure_php_command()
configure_php_command()
{
    # EXTRA_LIBS="-lresolv" \
    ./configure --prefix=$PHP_BASE \
                --sysconfdir=$PHP_FPM_CONFIG_DIR \
                --with-config-file-path=$PHP_CONFIG_DIR \
                $(is_installed_apache && echo --with-apxs2=$APACHE_BASE/bin/apxs || echo "") \
                --with-openssl=$OPENSSL_BASE \
                --enable-mysqlnd  \
                --with-zlib-dir=$ZLIB_BASE \
                --with-pdo-mysql=mysqlnd \
                --with-pdo-sqlite=$SQLITE_BASE --without-sqlite3 \
                --enable-zip \
                --with-zlib-dir=$ZLIB_BASE \
                --enable-soap \
                --with-libxml-dir=$LIBXML2_BASE \
                --with-gettext=$GETTEXT_BASE \
                --with-iconv=$LIBICONV_BASE \
                --with-mcrypt=$LIBMCRYPT_BASE \
                --enable-sockets \
                --enable-pcntl \
                --enable-sysvmsg \
                --enable-sysvsem \
                --enable-sysvshm \
                --enable-shmop \
                --enable-mbstring \
                --enable-xml \
                --disable-debug \
                --enable-bcmath \
                --enable-exif \
                --with-curl=$CURL_BASE \
                $( [ `echo "$PHP_VERSION 7.1.0"|tr " " "\n"|sort -rV|head -1` = "$PHP_VERSION" ] && echo "" || echo "--without-regex" ) \
                --enable-maintainer-zts \
                --with-gmp=$GMP_BASE \
                --enable-fpm \
                $( [ \"$OS_NAME\" != \"Darwin\" ] && echo --with-fpm-acl ) \
                --with-gd=$LIBGD_BASE \
                --with-freetype-dir=$FREETYPE_BASE \
                --enable-gd-native-ttf \
                --with-jpeg-dir=$JPEG_BASE \
                --with-png-dir=$LIBPNG_BASE \
                --with-xpm-dir=$LIBXPM_BASE \
                --with-zlib-dir=$ZLIB_BASE \
                $( [ `echo "$PHP_VERSION 7.1.0"|tr " " "\n"|sort -rV|head -1` = "$PHP_VERSION" ] && echo "--disable-zend-signals" ||echo " ") \
                --enable-opcache

                # --with-openssl=$OPENSSL_BASE --with-system-ciphers --with-kerberos=$KERBEROS_BASE

                # --with-libzip=$LIBZIP_BASE \

                # --with-fpm-systemd \  # Your system does not support systemd.

                # --with-imap=$IMAP_BASE --with-imap-ssl=$OPENSSL_BASE --with-kerberos=$KERBEROS_BASE

                # --without-iconv
                # --with-tidy=$TIDY_BASE
                # --with-imagick=$IMAGICK_BASE
                # --with-gearman=$GEARMAN_BASE
                # --enable-redis
                # --with-amqp
                # --with-libdir=lib64
                # --enable-embase

}
# }}}
# {{{ configure_libffi_command()
configure_libffi_command()
{
    local autoconf1=""
    local curr_version=""
    local minimum_version="2.68";

    local tmp_arr=( "/usr/bin/autoconf" "/usr/local/bin/autoconf" "`which autoconf`" );
    local i=""

    if [ "$OS_NAME" != "Darwin" ];then
        for i in ${tmp_arr[@]}; do
        {
            if [ -f "$i" ];then
                local curr_version=`$i --version|sed -n '1p'|awk '{print $NF;}'`;
                is_new_version "$curr_version" "$minimum_version"
                if [ "$?" = "0" ]; then
                    autoconf1=$i;
                    break;
                fi
            fi
        }
        done
    fi

    local old_path="$PATH"

    if [ ! -z "$autoconf1" -a "$autoconf1" != "`which autoconf`" ];then
        PATH="${autoconf1%/*}:$PATH"
    fi
    PATH="$PATH" \
    ./configure --prefix=$LIBFFI_BASE
    local flag=$?
    PATH="$old_path"
    return $flag;
}
# }}}
# {{{ configure_icu_command()
configure_icu_command()
{
    ./configure --prefix=$ICU_BASE
}
# }}}
# {{{ configure_nginx_command()
configure_nginx_command()
{
    ./configure --prefix=$NGINX_BASE \
                --conf-path=$NGINX_CONFIG_DIR/nginx.conf \
                $( is_new_version $NGINX_VERSION "1.12.0" && echo "--with-http_v2_module" || echo "--with-ipv6" ) \
                --with-threads \
                --with-http_mp4_module \
                --with-http_sub_module \
                --with-http_ssl_module \
                --with-http_stub_status_module \
                --with-http_realip_module \
                --with-pcre=../pcre-$PCRE_VERSION \
                --with-zlib=../zlib-$ZLIB_VERSION \
                --with-openssl=../openssl-$OPENSSL_VERSION \
                --with-http_gunzip_module \
                --with-http_gzip_static_module

    local flag="$?"
    if [ "$flag" != "0" ]; then
        return 1;
    fi

    # openssl编译不过去
    [ "$OS_NAME" = "Darwin" ] && \
    sed -i.bak 's/config --prefix/Configure darwin64-x86_64-cc --prefix/' ./objs/Makefile || :

    local flag="$?"
    if [ "$flag" != "0" ]; then
        return 1;
    fi

    # openssl编译不过去, 这个不起作用
    #$( [ \"$OS_NAME\" = \"Darwin\" ] && echo --with-openssl-opt=\"-darwin64-x86_64-cc\" ) \


                # the HTTP image filter module requires the GD library.
                # --with-http_image_filter_module \
                # --add-module=../nginx-accesskey-2.0.3 \
                # --add-module=../ngx_http_geoip2_module \
                # --with-poll_module \
                # --with-http_auth_request_module    enable ngx_http_auth_request_module
                # --with-http_random_index_module    enable ngx_http_random_index_module
                #--with-http_realip_module # 启用ngx_http_realip_module支持（这个模块允许从请求标头更改客户端的IP地址值，默认为关）
                # --with-http_gzip_static_module 启用ngx_http_gzip_static_module支持（在线实时压缩输出数据流）
                # --with-http_secure_link_module 启用ngx_http_secure_link_module支持（计算和检查要求所需的安全链接网址）
                # --with-http_degradation_module  启用ngx_http_degradation_module支持（允许在内存不足的情况下返回204或444码）
                # --with-http_stub_status_module 启用ngx_http_stub_status_module支持（获取nginx自上次启动以来的工作状态）
                # --with-mail 启用POP3/IMAP4/SMTP代理模块支持
                # --with-mail_ssl_module 启用ngx_mail_ssl_module支持
                # --with-rtsig_module # 启用rtsig模块支持（实时信号）
                # --with-file-aio # 启用file aio支持（一种APL文件传输格式）
}
# }}}
# {{{ configure_sphinxclient_command()
configure_sphinxclient_command()
{
    if [ "$OS_NAME" = "Darwin" ];then
        CXXCPP="gcc -E" \
        ./configure --prefix=$SPHINX_CLIENT_BASE
    else
        ./configure --prefix=$SPHINX_CLIENT_BASE
    fi
}
# }}}
# {{{ configure_libmemcached_command()
configure_libmemcached_command()
{
    #解决以下问题：
    #make[1]: *** [libmemcached/csl/libmemcached_libmemcached_la-context.lo] 错误 1
    #make[1]: *** 正在等待未完成的任务….
    #make[1]: *** [libmemcached/csl/libmemcached_libmemcached_la-parser.lo] 错误 1
    #
    #yum  install  gcc*
    #CC="gcc44" CXX="g++44"

    if [ "$OS_NAME" = 'Darwin' ];then
        # 1.0.18编译不过去时的处理
        if [ "$LIBMEMCACHED_VERSION" = "1.0.18" ]; then
            #在libmemcached/byteorder.cc的头部加上下面的代码即可：

            ##ifdef HAVE_SYS_TYPES_H
            ##include <sys/types.h>
            ##endif
            #同时，将clients/memflush.cc里if (opt_servers == false)的代码替换成if (opt_servers == NULL)，一切就顺利了。


            sed -i.bak 's/if (opt_servers == false)/if (opt_servers == NULL)/g' clients/memflush.cc

            local tmp_str=`sed -n '/#include/=' libmemcached/byteorder.cc`;
            local line_num=`echo $tmp_str | sed -n 's/^.* \([0-9]\{1,\}\)$/\1/p'`;
            if [ "$tmp_str" != "" ] && [ "$line_num" != "" ];then
                sed -i.bak "${line_num}a\\
\\
#ifdef HAVE_SYS_TYPES_H \\
#include <sys/types.h> \\
#endif
" libmemcached/byteorder.cc

            fi
        fi
    fi

    ./configure --prefix=$LIBMEMCACHED_BASE
                # --enable-libmemcachedprotocol
                # --enable-hsieh_hash
                # --enable-memaslap
                # --enable-deprecated
                # --enable-dtrace

                # --with-mysql=
                # --with-gearmand=
                # --with-memcached=
                # --with-sphinx-build=

}
# }}}
# {{{ configure_libevent_command()
configure_libevent_command()
{
    ./autogen.sh && \
    CPPFLAGS="$(get_cppflags $OPENSSL_BASE/include)" LDFLAGS="$(get_ldflags $OPENSSL_BASE/lib)" \
    PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
    ./configure --prefix=$LIBEVENT_BASE --enable-openssl
}
# }}}
# {{{ configure_pdf2htmlEX_command()
configure_pdf2htmlEX_command()
{
    local gcc=""
    local minimum_version="4.6.3"
    local curr_version=""
    local tmp_arr=( "/usr/bin/gcc" "/usr/local/bin/gcc" "`which gcc`" );
    local i=""
    if [ "$OS_NAME" != "Darwin" ];then
        for i in ${tmp_arr[@]}; do
        {
            if [ -f "$i" ];then
                local curr_version=`$i --version|sed -n '1p'|awk '{print $NF;}'`;
                is_new_version "$curr_version" "$minimum_version"
                if [ "$?" = "0" ]; then
                    gcc=$i;
                    break;
                fi
            fi
        }
        done
    fi

    if [ "$OS_NAME" != 'Darwin' -a -z "$gcc" ];then
        echo "please update your compiler." >&2
        return 1;
    fi

    sed -i.bak "s/#include \"$(sed_quote poppler/GfxState.h)\"/#include \"$(sed_quote ${POPPLER_BASE}/include/poppler/GfxState.h)\"/" $POPPLER_BASE/include/poppler/splash/SplashBitmap.h

    #指定编译器,因为编译器版本太低，重新编译了编译器

     cmake ./ -DCMAKE_INSTALL_PREFIX=$PDF2HTMLEX_BASE \
              $([ "$OS_NAME" != 'Darwin' ] && echo "
              -DCMAKE_CXX_COMPILER=$(dirname $gcc)/g++ \
              -DCMAKE_C_COMPILER=$gcc
              ")
}
# }}}
# {{{ configure_libsodium_command()
configure_libsodium_command()
{
    ./configure --prefix=$LIBSODIUM_BASE
}
# }}}
# {{{ configure_ImageMagick_command()
configure_ImageMagick_command()
{
    # ld: symbol(s) not found for architecture x86_64
    # 用下面的CPPFLAGS LDFLAGS 或 --without-png
    CPPFLAGS="$(get_cppflags ${ZLIB_BASE}/include ${LIBPNG_BASE}/include ${FREETYPE_BASE}/include ${FONTCONFIG_BASE}/include ${JPEG_BASE}/include $([ "$OS_NAME" = 'Darwin' ] && echo " $LIBX11_BASE/include") )" \
    LDFLAGS="$(get_ldflags ${ZLIB_BASE}/lib ${LIBPNG_BASE}/lib ${FREETYPE_BASE}/lib ${FONTCONFIG_BASE}/lib ${JPEG_BASE}/lib $([ "$OS_NAME" = 'Darwin' ] && echo " $LIBX11_BASE/lib") )" \
    ./configure --prefix=$IMAGEMAGICK_BASE \
                $( [ \"$OS_NAME\" != \"Darwin\" ] && echo '--enable-opencl' )
                #--without-png \
}
# }}}
# {{{ configure_php_swoole_command()
configure_php_swoole_command()
{
    local kernel_release=$(uname -r);
    kernel_release=${kernel_release%%-*}

    local is_2=$( [ `echo "$SWOOLE_VERSION 2.0.0"|tr " " "\n"|sort -rV|head -1` = "$SWOOLE_VERSION" ] && echo "1" || echo "0")

    # 编译时如果没有pcre，使用时会有意想不到的结果 $memory_table->count() > 0，但是foreach 结果为空
    CPPFLAGS="$( get_cppflags $OPENSSL_BASE/include $PCRE_BASE/include)" LDFLAGS="$(get_ldflags $OPENSSL_BASE/lib $PCRE_BASE/lib )" \
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --enable-sockets \
                --enable-openssl \
                $( [ `echo "$SWOOLE_VERSION 1.9.0"|tr " " "\n"|sort -rV|head -1` = "$SWOOLE_VERSION" ] \
                && echo "--with-openssl$([ `echo "$SWOOLE_VERSION 2.0.0"|tr " " "\n"|sort -rV|head -1` != "2.0.0" ] \
                && echo  "-dir" || echo "")=$OPENSSL_BASE" || echo " " ) \
                --with-swoole \
                --enable-swoole \
                $( [ "$is_2" = "1" ] && echo "
                --enable-coroutine \
                --enable-async-redis \
                --enable-thread \
                --enable-ringbuffer" || echo " ") \

                #--enable-http2 \
                #-enable-jemalloc \

                # CentOS 7.1  php7.1.4 swoole2.0.7  php -m 报错 Segmentation fault
                #$( [ `echo "$kernel_release 2.6.33" | tr " " "\n"|sort -rV|head -1 ` = "$kernel_release" ] && echo "--enable-hugepage" || echo "" )
}
# }}}
# {{{ configure_php_amqp_command()
configure_php_amqp_command()
{
    local tmp_str=""
    if echo "$HOST_TYPE"|grep -q x86_64 ; then
        tmp_str="64"
    fi

    CPPFLAGS="$(get_cppflags $RABBITMQ_C_BASE/include)" \
    LDFLAGS="$(get_ldflags $RABBITMQ_C_BASE/lib${tmp_str})" \
    ./configure --with-php-config=$PHP_BASE/bin/php-config --with-amqp \
                --with-librabbitmq-dir=$RABBITMQ_C_BASE
}
# }}}
# {{{ configure_php_tidy_command()
configure_php_tidy_command()
{
    # sed -i.bak.$$ 's/\<buffio.h/tidybuffio.h/' tidy.c
    sed $( [ "$OS_NAME" = "Darwin" ] && echo "-i ''" ||  echo '-i ' ) 's/\([^a-zA-Z0-9_-]\)buffio.h/\1tidybuffio.h/' tidy.c
    ./configure --with-php-config=$PHP_BASE/bin/php-config --with-tidy=$TIDY_BASE
}
# }}}
# {{{ configure_php_maxminddb_command()
configure_php_maxminddb_command()
{
    CPPFLAGS="$(get_cppflags $LIBMAXMINDDB_BASE/include)" LDFLAGS="$(get_ldflags $LIBMAXMINDDB_BASE/lib)" \
    ./configure --with-php-config=$PHP_BASE/bin/php-config --with-maxminddb
}
# }}}
# {{{ configure_libmaxminddb_command()
configure_libmaxminddb_command()
{
    ./configure --prefix=$LIBMAXMINDDB_BASE
}
# }}}
# }}}

# {{{ function compile_rabbitmq()
function compile_rabbitmq()
{
    compile_libiconv

    echo "compile_rabbitmq 未完成" >&2
    return 1;
    is_installed rabbitmq
    if [ "$?" = "0" ];then
        return;
    fi

    RABBITMQ_CONFIGURE="
    ./configure --prefix=$LIBQRENCODE_BASE \
                --with-libiconv-prefix=$LIBICONV_BASE
    "

    compile "rabbitmq" "$RABBITMQ_FILE_NAME" "rabbitmq-$RABBITMQ_VERSION" "$RABBITMQ_BASE" "RABBITMQ_CONFIGURE"
}
# }}}
# {{{ function compile_php_extension_rabbitmq()
function compile_php_extension_rabbitmq()
{
    compile_rabbitmq

    echo "compile_php_extension_rabbitmq 未完成" >&2
    return 1;
    is_installed_php_extension rabbitmq
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_rabbitmq_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --with-librabbitmq-dir=$RABBITMQ_C_BASE
    "

    compile "php_extension_rabbitmq" "$rabbitmq_FILE_NAME" "rabbitmq-$rabbitmq_VERSION" "rabbitmq.so" "PHP_EXTENSION_rabbitmq_CONFIGURE"

    /bin/rm -rf package.xml
#http://pecl.php.net/get/amqp-1.7.1.tgz
echo_build_start rabbitmq
tar zxf ""
cd
 $PHP_BASE/bin/phpize
 ./configure --with-php-config=$PHP_BASE/bin/php-config --with-librabbitmq-dir=$RABBITMQ_C_BASE
make_run "$?/PHP rabbitmq"
if [ "$?" != "0" ];then
    exit 1;
fi
cd ..

/bin/rm -rf php-rabbitmq-$RABBITMQ_VERSION


#other ....
# --with-wbxml=$WBXML_BASE
# --enable-http --with-http-curl-requests=$CURL_BASE --with-http-curl-libevent=$LIBEVENT_BASE --with-http-zlib-compression=$ZLIB_BASE --with-http-magic-mime=$MAGIC_BASE

}
# }}}
# {{{ function check_soft_updates()
function check_soft_updates()
{
    #yum update -y curl nss
    #which curl
    #which sed
    #which sort 
    #which head


#    check_version zend
#    check_version jquery
#    check_version famous
#    check_version famous_framework
#    check_version famous_angular
#check_version swfupload
#    exit;
    check_version ckeditor
    check_version composer
    check_version memcached
    check_version apache
    check_version apr
    check_version apr_util
    check_version postgresql
    check_version libsodium
    check_version pango
    check_version poppler
    check_version fontconfig
    check_version expat
    check_version cairo
    check_version pixman
    check_version jpeg
    check_version libgd
    check_version qrencode
    check_version libmemcached
    check_version kerberos
    check_version imap
    check_version inputproto
    check_version xextproto
    check_version xproto
    check_version xtrans
    check_version libXau
    check_version libX11
    check_version libpthread_stubs
    check_version libxcb
    check_version xcb_proto
    check_version macros
    check_version xf86bigfontproto
    check_version kbproto
    check_version libXpm
    check_version libmcrypt
    check_version libxslt
    check_version libxml2
    check_version gettext
    check_version libiconv
    check_version libjpeg
    check_version pcre
    check_version boost
    check_version gearman
    check_version gearmand
    check_version libevent
    check_version curl
    check_version fontforge
    check_version libpng
    check_version util_linux
    check_version glib
    check_version freetype
    check_version harfbuzz
    check_version nasm
    check_version json_c
    check_version libfastjson
    check_version nginx
    check_version rsyslog
    check_version liblogging
    check_version libgcrypt
    check_version libgpg_error
    check_version libestr
    check_version hiredis
    check_version redis
    check_version libunwind
    check_version zeromq
    check_version sqlite
    check_version swoole
    check_version openssl
    check_version icu
    check_version zlib
    check_version libzip
    check_version gmp
    check_version php
    check_version mysql
    check_version imagemagick
    check_version pkgconfig

    # github
    check_version re2c
    check_version tidy
    check_version sphinx
    check_version pecl_sphinx
    check_version openjpeg
    check_version fontforge
    check_version pdf2htmlEX

    check_pecl_pthreads_version
    check_pecl_solr_version
    check_pecl_mailparse_version
    check_pecl_amqp_version
    check_pecl_http_version
    check_pecl_propro_version
    check_pecl_raphf_version
    check_pecl_apcu_version
    check_pecl_apcu_bc_version
    check_pecl_libevent_version
    check_pecl_event_version
    check_pecl_xdebug_version
    check_pecl_dio_version
    check_pecl_memcached_version
    check_pecl_qrencode_version
    check_pecl_mongodb_version
    check_pecl_zmq_version
    check_pecl_redis_version
    check_pecl_imagick_version
    check_pecl_phalcon_version
    check_pecl_yaf_version
    check_pecl_libsodium_version

    check_version smarty
    check_version rabbitmq
    check_version libmaxminddb
    check_version maxmind_db_reader_php
    check_version web_service_common_php
    check_version geoip2_php
    check_version geoipupdate
    check_version electron
    check_version phantomjs
    check_version laravel
    check_version laravel_framework
}
# }}}
# {{{ check all soft version
# {{{ function check_version()
function check_version()
{
    local func_name="check_${1}_version";
    function_exists "$func_name";

    if [ "$?" != "0" ];
    then
        echo "${1}的版本检测更新未实现"
        return 1;
    fi
    $func_name
}
# }}}
# {{{ function check_openssl_version()
function check_openssl_version()
{
    local tmp=""
    if [ "$#" = "0" ]; then
        check_openssl_version 1
    fi

    #只查找当前小版本
    if [ "$1" = "1" ]; then
        local tmp=${OPENSSL_VERSION%.*}
    fi

    local versions=`curl -k https://www.openssl.org/source/ 2>/dev/null|sed -n "s/^.\{1,\}>openssl-\($tmp[0-9a-zA-Z.]\{2,\}\).tar.gz.\{1,\}/\1/p"|sort -rV`
    local new_version=`echo "$versions"|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测openssl新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $OPENSSL_VERSION $new_version
    if [ "$?" = "0" ];then
        echo -e "openssl version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "openssl current version: \033[0;33m${OPENSSL_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_redis_version()
function check_redis_version()
{
    local versions=`curl -k https://redis.io/ 2>/dev/null|sed -n 's/^.\{1,\}redis-\([0-9a-zA-Z.]\{2,\}\).tar.gz.\{1,\}/\1/p'|sort -rV`
    local new_version=`echo "$versions"|head -1`;
    if [ -z "$new_version" ];then
        echo -e "探测redis新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    echo "$new_version" |grep -iq 'RC'
    if [ "$?" = "0" ]; then
        local tmp_version1=`echo "$versions"|grep -iv 'RC' |head -1`;
        local tmp_version2=`echo "$new_version"|sed -n 's/^\([0-9._-]\{1,\}\)\([Rr][Cc]\).\{1,\}$/\1/p'`;
        if [ "$tmp_version1" = "$tmp_version2" ];then
            new_version=$tmp_version2;
        fi
    fi

    is_new_version $REDIS_VERSION $new_version
    if [ "$?" = "0" ];then
        echo -e "redis version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "redis current version: \033[0;33m${REDIS_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_icu_version()
function check_icu_version()
{
    # http://site.icu-project.org/download
    local new_version=`curl -k https://fossies.org/linux/misc/ 2>/dev/null|sed -n 's/^.\{1,\}>icu4c-\([0-9a-zA-Z._]\{2,\}\)-src.tgz<.\{1,\}/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测icu新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $ICU_VERSION ${new_version//_/.}
    if [ "$?" = "0" ];then
        echo -e "icu version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "icu current version: \033[0;33m${ICU_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_curl_version()
function check_curl_version()
{
    local new_version=`curl -k https://curl.haxx.se/download/ 2>/dev/null|sed -n 's/^.\{1,\}>curl-\([0-9a-zA-Z._]\{2,\}\).tar.gz<.\{1,\}/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测curl新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $CURL_VERSION ${new_version//_/.}
    if [ "$?" = "0" ];then
        echo -e "curl version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "curl current version: \033[0;33m${CURL_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_zlib_version()
function check_zlib_version()
{
    local new_version=`curl -k http://zlib.net 2>/dev/null|sed -n 's/^.\{0,\}"zlib-\([0-9a-zA-Z._]\{2,\}\).tar.gz".\{0,\}/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测zlib新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $ZLIB_VERSION ${new_version//_/.}
    if [ "$?" = "0" ];then
        echo -e "zlib version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "zlib current version: \033[0;33m${ZLIB_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_libunwind_version()
function check_libunwind_version()
{
    local new_version=`curl -k http://download.savannah.gnu.org/releases/libunwind/ 2>/dev/null|sed -n 's/^.\{0,\}"libunwind-\([0-9a-zA-Z._]\{2,\}\).tar.gz".\{0,\}/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测libunwind新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $LIBUNWIND_VERSION ${new_version//_/.}
    if [ "$?" = "0" ];then
        echo -e "libunwind version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "libunwind current version: \033[0;33m${LIBUNWIND_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_freetype_version()
function check_freetype_version()
{
    local new_version=`curl -k https://www.freetype.org/ 2>/dev/null|sed -n 's/^.\{0,\}<h4>FreeType \([0-9.]\{3,\}\)<\/h4>.\{0,\}$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测freetype新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $FREETYPE_VERSION ${new_version//_/.}
    if [ "$?" = "0" ];then
        echo -e "freetype version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "freetype current version: \033[0;33m${FREETYPE_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_harfbuzz_version()
function check_harfbuzz_version()
{
    check_ftp_version harfbuzz ${HARFBUZZ_VERSION} https://www.freedesktop.org/software/harfbuzz/release/ 's/^.\{1,\}>harfbuzz-\([0-9.]\{1,\}\)\.tar\.bz2<.\{0,\}$/\1/p'
}
# }}}
# {{{ function check_libzip_version()
function check_libzip_version()
{
    local versions=`curl -k https://nih.at/libzip/ 2>/dev/null|sed -n 's/^.\{0,\}"libzip-\([0-9a-zA-Z._]\{2,\}\).tar.gz".\{0,\}/\1/p'|sort -rV`
    local new_version=`echo "$versions"|head -1`;
    if [ -z "$new_version" ];then
        echo -e "探测libzip新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    echo "$new_version" |grep -iq 'RC'
    if [ "$?" = "0" ]; then
        local tmp_version1=`echo "$versions"|grep -iv 'RC' |head -1`;
        local tmp_version2=`echo "$new_version"|sed -n 's/^\([0-9._-]\{1,\}\)\([Rr][Cc]\).\{1,\}$/\1/p'`;
        if [ "$tmp_version1" = "$tmp_version2" ];then
            new_version=$tmp_version2;
        fi
    fi

    is_new_version $LIBZIP_VERSION ${new_version//_/.}
    if [ "$?" = "0" ];then
        echo -e "libzip version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "libzip current version: \033[0;33m${LIBZIP_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_php_version()
function check_php_version()
{
    local tmp=""
    if [ "$#" = "0" ]; then
        check_php_version 1
    fi

    #只查找当前小版本
    if [ "$1" = "1" ]; then
        local tmp=${PHP_VERSION%.*}
    fi

    local versions=`curl http://php.net/downloads.php 2>/dev/null|sed -n "s/^.\{1,\}php-\(${tmp}[0-9.]\{1,\}\)\.tar\.xz.\{1,\}$/\1/p"|sort -rV`
    local new_version=`echo "$versions"|head -1`;
    if [ -z "$new_version" ];then
        echo -e "探测php新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    echo "$new_version" |grep -iq 'RC'
    if [ "$?" = "0" ]; then
        local tmp_version1=`echo "$versions"|grep -iv 'RC' |head -1`;
        local tmp_version2=`echo "$new_version"|sed -n 's/^\([0-9._-]\{1,\}\)\([Rr][Cc]\).\{1,\}$/\1/p'`;
        if [ "$tmp_version1" = "$tmp_version2" ];then
            new_version=$tmp_version2;
        fi
    fi

    is_new_version $PHP_VERSION $new_version
    if [ "$?" = "0" ];then
        echo -e "php version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "php current version: \033[0;33m${PHP_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_gmp_version()
function check_gmp_version()
{
    local new_version=`curl ftp://ftp.gmplib.org/pub/gmp/ 2>/dev/null|sed -n 's/^.\{1,\}gmp-\([0-9.]\{1,\}\)\.tar\.xz.\{1,\}$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测gmp新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $GMP_VERSION $new_version
    if [ "$?" = "0" ];then
        echo -e "gmp version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "gmp current version: \033[0;33m${GMP_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_mysql_version()
function check_mysql_version()
{
    local new_version=`curl -k https://dev.mysql.com/downloads/mysql/ 2>/dev/null |sed -n 's/<h1> \{0,\}MySQL \{1,\}Community \{1,\}Server \{0,\}\(.\{1,\}\) \{0,\}<\/h1>/\1/p'|sort -rV|head -1`;
    new_version=${new_version// /}
    if [ -z "$new_version" ];then
        echo -e "探测mysql新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $MYSQL_VERSION $new_version
    if [ "$?" = "0" ];then
        echo -e "mysql version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "mysql current version: \033[0;33m${MYSQL_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_nginx_version()
function check_nginx_version()
{
    # Mainline version
    # Stable version
    # Legacy versions
    # 难点是取到stable中的版本
    local new_version=`curl -k http://nginx.org/en/download.html 2>/dev/null |sed -n 's/^.\{1,\}Stable version\(.\{1,\}\)Legacy versions.\{1,\}$/\1/p'|sed -n 's/^.\{1,\}nginx-\([0-9.]\{1,\}\)\.tar\.gz".\{1,\}$/\1/gp'|sort -rV|head -1`;
    new_version=${new_version// /}
    if [ -z "$new_version" ];then
        echo -e "探测nginx新版本\033[0;31m失败\033[0m" >&2
            return 1;
    fi

    is_new_version $NGINX_VERSION $new_version
    if [ "$?" = "0" ];then
        echo -e "nginx version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "nginx current version: \033[0;33m${NGINX_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"

}
# }}}
# {{{ function check_json_c_version()
function check_json_c_version()
{
    check_github_soft_version json-c $JSON_VERSION "https://github.com/json-c/json-c/releases" "json-c-\([0-9.]\{1,\}\)-[0-9.]\{1,\}.tar.gz" 1
}
# }}}
# {{{ function check_libfastjson_version()
function check_libfastjson_version()
{
    check_github_soft_version libfastjson $LIBFASTJSON_VERSION "https://github.com/rsyslog/libfastjson/releases"
}
# }}}
# {{{ function check_imagemagick_version()
function check_imagemagick_version()
{
    local versions=`curl http://www.imagemagick.org/download/releases/ 2>/dev/null|sed -n 's/^.\{1,\} href="ImageMagick-\([0-9.-]\{1,\}\).tar.gz">.\{1,\}$/\1/p'|sort -rV`
    local new_version=`echo "$versions"|head -1`;
    if [ -z "$new_version" ];then
        echo -e "探测imagemagick新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    echo "$new_version" |grep -iq 'RC'
    if [ "$?" = "0" ]; then
        local tmp_version1=`echo "$versions"|grep -iv 'RC' |head -1`;
        local tmp_version2=`echo "$new_version"|sed -n 's/^\([0-9._-]\{1,\}\)\([Rr][Cc]\).\{1,\}$/\1/p'`;
        if [ "$tmp_version1" = "$tmp_version2" ];then
            new_version=$tmp_version2;
        fi
    fi

    is_new_version ${IMAGEMAGICK_VERSION} ${new_version}
    if [ "$?" = "0" ];then
        echo -e "imagemagick version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "imagemagick current version: \033[0;33m${IMAGEMAGICK_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_pkgconfig_version()
function check_pkgconfig_version()
{
    local new_version=`curl -k https://pkg-config.freedesktop.org/releases/ 2>/dev/null |sed -n 's/^.\{1,\} href="pkg-config-\([0-9.]\{1,\}\).tar.gz">.\{1,\}$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测pkgconfig新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $PKGCONFIG_VERSION $new_version
    if [ "$?" = "0" ];then
        echo -e "pkgconfig version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "pkgconfig current version: \033[0;33m${PKGCONFIG_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_re2c_version()
function check_re2c_version()
{
    check_github_soft_version re2c $RE2C_VERSION "https://github.com/skvadrik/re2c/releases"
}
# }}}
# {{{ function check_openjpeg_version()
function check_openjpeg_version()
{
    check_github_soft_version openjpeg $OPENJPEG_VERSION "https://github.com/uclouvain/openjpeg/releases"
}
# }}}
# {{{ function check_libgd_version()
function check_libgd_version()
{
    check_github_soft_version libgd $LIBGD_VERSION "https://github.com/libgd/libgd/releases" "gd-\([0-9.]\{1,\}\).tar.gz" 1
}
# }}}
# {{{ function check_fontforge_version()
function check_fontforge_version()
{
    check_github_soft_version fontforge $FONTFORGE_VERSION "https://github.com/fontforge/fontforge/releases"
}
# }}}
# {{{ function check_composer_version()
function check_composer_version()
{
    check_github_soft_version composer $COMPOSER_VERSION "https://github.com/composer/composer/releases"
}
# }}}
# {{{ function check_gearmand_version()
function check_gearmand_version()
{
    check_github_soft_version gearmand $GEARMAND_VERSION "https://github.com/gearman/gearmand/releases"
}
# }}}
# {{{ function check_gearman_version()
function check_gearman_version()
{
    check_github_soft_version gearman $PHP_GEARMAN_VERSION "https://github.com/wcgallego/pecl-gearman/releases" "gearman-\([0-9.]\{1,\}\).tar.gz" 1
}
# }}}
# {{{ function check_pdf2htmlEX_version()
function check_pdf2htmlEX_version()
{
    check_github_soft_version pdf2htmlEX $PDF2HTMLEX_VERSION "https://github.com/coolwanglu/pdf2htmlEX/releases"
}
# }}}
# {{{ function check_nasm_version()
function check_nasm_version()
{
    local new_version=`curl -k http://www.nasm.us/ 2>/dev/null |sed -n '/The latest stable version of NASM is/{n;s/^.\{1,\}>\([0-9].\{1,\}\)<.\{1,\}$/\1/p;}'`;
    new_version=${new_version// /}
    if [ -z "$new_version" ];then
        echo -e "探测nasm新版本\033[0;31m失败\033[0m" >&2
            return 1;
    fi

    is_new_version $NASM_VERSION $new_version
    if [ "$?" = "0" ];then
        echo -e "nasm version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "nasm current version: \033[0;33m${NASM_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"

}
# }}}
# {{{ function check_tidy_version()
function check_tidy_version()
{
    check_github_soft_version tidy $TIDY_VERSION "https://github.com/htacg/tidy-html5/releases"
}
# }}}
# {{{ function check_smarty_version()
function check_smarty_version()
{
    check_github_soft_version smarty $SMARTY_VERSION "https://github.com/smarty-php/smarty/releases"
}
# }}}
# {{{ function check_ckeditor_version()
function check_ckeditor_version()
{
    check_github_soft_version ckeditor $CKEDITOR_VERSION "https://github.com/ckeditor/ckeditor-dev/releases"
}
# }}}
# {{{ function check_rabbitmq_version()
function check_rabbitmq_version()
{
    check_github_soft_version rabbitmq-c $RABBITMQ_C_VERSION "https://github.com/alanxz/rabbitmq-c/releases"
}
# }}}
# {{{ function check_libmaxminddb_version()
function check_libmaxminddb_version()
{
    check_github_soft_version libmaxminddb $LIBMAXMINDDB_VERSION "https://github.com/maxmind/libmaxminddb/releases"
}
# }}}
# {{{ function check_maxmind_db_reader_php_version()
function check_maxmind_db_reader_php_version()
{
    check_github_soft_version MaxMind-DB-Reader-php $MAXMIND_DB_READER_PHP_VERSION "https://github.com/maxmind/MaxMind-DB-Reader-php/releases"
}
# }}}
# {{{ function check_web_service_common_php_version()
function check_web_service_common_php_version()
{
    check_github_soft_version web-service-common-php $WEB_SERVICE_COMMON_PHP_VERSION "https://github.com/maxmind/web-service-common-php/releases"
}
# }}}
# {{{ function check_geoip2_php_version()
function check_geoip2_php_version()
{
    check_github_soft_version GeoIP2-php $GEOIP2_PHP_VERSION "https://github.com/maxmind/GeoIP2-php/releases"
}
# }}}
# {{{ function check_geoipupdate_version()
function check_geoipupdate_version()
{
    check_github_soft_version geoipupdate $GEOIPUPDATE_VERSION "https://github.com/maxmind/geoipupdate/releases"
}
# }}}
# {{{ function check_electron_version()
function check_electron_version()
{
    check_github_soft_version electron $ELECTRON_VERSION "https://github.com/electron/electron/releases"
}
# }}}
# {{{ function check_phantomjs_version()
function check_phantomjs_version()
{
    check_github_soft_version phantomjs $PHANTOMJS_VERSION "https://github.com/ariya/phantomjs/releases"
}
# }}}
# {{{ function check_laravel_version()
function check_laravel_version()
{
    check_github_soft_version laravel $LARAVEL_VERSION "https://github.com/laravel/laravel/releases"
}
# }}}
# {{{ function check_laravel_framework_version()
function check_laravel_framework_version()
{
    check_github_soft_version 'laravel\/framework' $LARAVEL_FRAMEWORK_VERSION "https://github.com/laravel/framework/releases"
}
# }}}
# {{{ function check_zeromq_version()
function check_zeromq_version()
{
    check_github_soft_version zeromq $ZEROMQ_VERSION "https://github.com/zeromq/libzmq/releases"
}
# }}}
# {{{ function check_hiredis_version()
function check_hiredis_version()
{
    check_github_soft_version hiredis $HIREDIS_VERSION "https://github.com/redis/hiredis/releases"
}
# }}}
# {{{ function check_pecl_pthreads_version()
function check_pecl_pthreads_version()
{
    check_php_pecl_version pthreads $PTHREADS_VERSION
}
# }}}
# {{{ function check_pecl_solr_version()
function check_pecl_solr_version()
{
    check_php_pecl_version solr $SOLR_VERSION
}
# }}}
# {{{ function check_pecl_mailparse_version()
function check_pecl_mailparse_version()
{
    check_php_pecl_version mailparse $MAILPARSE_VERSION
}
# }}}
# {{{ function check_pecl_amqp_version()
function check_pecl_amqp_version()
{
    check_php_pecl_version amqp $AMQP_VERSION
}
# }}}
# {{{ function check_pecl_http_version()
function check_pecl_http_version()
{
    check_php_pecl_version pecl_http $PECL_HTTP_VERSION
}
# }}}
# {{{ function check_pecl_propro_version()
function check_pecl_propro_version()
{
    check_php_pecl_version propro $PROPRO_VERSION
}
# }}}
# {{{ function check_pecl_raphf_version()
function check_pecl_raphf_version()
{
    check_php_pecl_version raphf $RAPHF_VERSION
}
# }}}
# {{{ function check_pecl_apcu_version()
function check_pecl_apcu_version()
{
    check_php_pecl_version apcu $APCU_VERSION
}
# }}}
# {{{ function check_pecl_apcu_bc_version()
function check_pecl_apcu_bc_version()
{
    check_php_pecl_version apcu_bc $APCU_BC_VERSION
}
# }}}
# {{{ function check_pecl_event_version()
function check_pecl_event_version()
{
    check_php_pecl_version event $EVENT_VERSION
}
# }}}
# {{{ function check_pecl_libevent_version()
function check_pecl_libevent_version()
{
    check_php_pecl_version libevent $PHP_LIBEVENT_VERSION
}
# }}}
# {{{ function check_pecl_dio_version()
function check_pecl_dio_version()
{
    #check_github_soft_version pecl-system-dio $DIO_VERSION "https://github.com/php/pecl-system-dio/releases"
    check_php_pecl_version dio $DIO_VERSION
}
# }}}
# {{{ function check_pecl_xdebug_version()
function check_pecl_xdebug_version()
{
    check_php_pecl_version xdebug $XDEBUG_VERSION
}
# }}}
# {{{ function check_pecl_libsodium_version()
function check_pecl_libsodium_version()
{
    check_php_pecl_version libsodium $PHP_LIBSODIUM_VERSION
}
# }}}
# {{{ function check_pecl_memcached_version()
function check_pecl_memcached_version()
{
    #check_github_soft_version php-memcached $PHP_MEMCACHED_VERSION "https://github.com/php-memcached-dev/php-memcached/releases"
    check_php_pecl_version memcached $PHP_MEMCACHED_VERSION
}
# }}}
# {{{ function check_pecl_imagick_version()
function check_pecl_imagick_version()
{
    #check_github_soft_version php-imagick $IMAGICK_VERSION "https://github.com/mkoppanen/imagick/releases" "\([0-9.]\{5,\}\(RC\)\{0,1\}[0-9]\{1,\}\)\.tar\.gz" 1
    check_php_pecl_version imagick $IMAGICK_VERSION
}
# }}}
# {{{ function check_pecl_redis_version()
function check_pecl_redis_version()
{
    #check_github_soft_version phpredis $PHP_REDIS_VERSION "https://github.com/phpredis/phpredis/releases" "\([0-9.]\{5,\}\(RC\)\{0,1\}[0-9]\{1,\}\)\.tar\.gz" 1
    check_php_pecl_version redis $PHP_REDIS_VERSION
}
# }}}
# {{{ function check_pecl_qrencode_version()
function check_pecl_qrencode_version()
{
    check_github_soft_version qrencode $QRENCODE_VERSION "https://github.com/chg365/qrencode/releases"
}
# }}}
# {{{ function check_pecl_yaf_version()
function check_pecl_yaf_version()
{
    check_php_pecl_version yaf $YAF_VERSION
}
# }}}
# {{{ function check_pecl_mongodb_version()
function check_pecl_mongodb_version()
{
    check_php_pecl_version mongodb $PHP_MONGODB_VERSION
}
# }}}
# {{{ function check_pecl_zmq_version()
function check_pecl_zmq_version()
{
    check_github_soft_version php-zmq $PHP_ZMQ_VERSION "https://github.com/mkoppanen/php-zmq/releases"
}
# }}}
# {{{ function check_pecl_phalcon_version()
function check_pecl_phalcon_version()
{
    check_github_soft_version phalcon $PHALCON_VERSION "https://github.com/phalcon/cphalcon/releases"
}
# }}}
# {{{ function check_sphinx_version()
function check_sphinx_version()
{
    check_github_soft_version sphinx $SPHINX_VERSION "https://github.com/sphinxsearch/sphinx/releases"
}
# }}}
# {{{ function check_swoole_version()
function check_swoole_version()
{
    check_github_soft_version swoole $SWOOLE_VERSION "https://github.com/swoole/swoole-src/releases" "v\([0-9.]\{5,\}\)\(-stable\)\{0,1\}\.tar\.gz" 1
}
# }}}
# {{{ function check_libevent_version()
function check_libevent_version()
{
    check_github_soft_version libevent $LIBEVENT_VERSION "https://github.com/libevent/libevent/releases" "release-\([0-9.]\{5,\}\)\(-stable\)\{0,1\}\.tar\.gz" 1
}
# }}}
# {{{ function check_rsyslog_version()
function check_rsyslog_version()
{
    check_github_soft_version rsyslog $RSYSLOG_VERSION "https://github.com/rsyslog/rsyslog/releases" "v\([0-9.]\{5,\}\)\(-stable\)\{0,1\}\.tar\.gz" 1
}
# }}}
# {{{ function check_liblogging_version()
function check_liblogging_version()
{
    check_github_soft_version liblogging $LIBLOGGING_VERSION "https://github.com/rsyslog/liblogging/releases" "v\([0-9.]\{5,\}\)\(-stable\)\{0,1\}\.tar\.gz" 1
}
# }}}
# {{{ function check_libgcrypt_version()
function check_libgcrypt_version()
{
    local new_version=`curl -k ftp://ftp.gnupg.org/gcrypt/libgcrypt/ 2>/dev/null |sed -n 's/^.\{1,\} libgcrypt-\([0-9.]\{1,\}\).tar.gz$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测libgcrypt新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $LIBGCRYPT_VERSION $new_version
    if [ "$?" = "0" ];then
        echo -e "libgcrypt version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "libgcrypt current version: \033[0;33m${LIBGCRYPT_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_libgpg_error_version()
function check_libgpg_error_version()
{
    local new_version=`curl -k ftp://ftp.gnupg.org/gcrypt/libgpg-error/ 2>/dev/null |sed -n 's/^.\{1,\} libgpg-error-\([0-9.]\{1,\}\).tar.gz$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测libgpg-error新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $LIBGPG_ERROR_VERSION $new_version
    if [ "$?" = "0" ];then
        echo -e "libgpg-error version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "libgpg-error current version: \033[0;33m${LIBGPG_ERROR_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_gettext_version()
function check_gettext_version()
{
    check_ftp_gnu_org_version gettext $GETTEXT_VERSION
}
# }}}
# {{{ function check_libiconv_version()
function check_libiconv_version()
{
    check_ftp_gnu_org_version libiconv $LIBICONV_VERSION
}
# }}}
# {{{ function check_glib_version()
function check_glib_version()
{
    local new_version=`curl -k https://developer.gnome.org/glib/ 2>/dev/null |sed -n 's/^.\{1,\}>\([0-9._-]\{1,\}\)<\/a><\/li>.\{0,\}$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测glib新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $GLIB_VERSION $new_version
    if [ "$?" = "0" ];then
        echo -e "glib version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "glib current version: \033[0;33m${GLIB_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"

    #check_github_soft_version glib $GLIB_VERSION "https://github.com/GNOME/glib/releases"
}
# }}}
# {{{ function check_util_linux_version()
function check_util_linux_version()
{
    check_github_soft_version util-linux $UTIL_LINUX_VERSION "https://github.com/karelzak/util-linux/releases"
}
# }}}
# {{{ function check_libffi_version()
function check_libffi_version()
{
    check_github_soft_version libffi $LIBFFI_VERSION "https://github.com/libffi/libffi/releases"
}
# }}}
# {{{ function check_libestr_version()
function check_libestr_version()
{
    check_github_soft_version libestr $LIBESTR_VERSION "https://github.com/rsyslog/libestr/releases" "v\([0-9.]\{5,\}\)\(-stable\)\{0,1\}\.tar\.gz" 1
}
# }}}
# {{{ function check_libpng_version()
function check_libpng_version()
{
    check_github_soft_version libpng $LIBPNG_VERSION "https://github.com/glennrp/libpng/releases" "v\([0-9.]\{5,\}\)\.tar\.gz" 1
}
# }}}
# {{{ function check_kerberos_version()
function check_kerberos_version()
{
    local new_version=`curl -k http://web.mit.edu/kerberos/dist/ 2>/dev/null |sed -n 's/.\{1,\}>krb5-\([0-9.-]\{1,\}\).tar.gz<.\{1,\}$/\1/p'|tr - .|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测kerberos新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $KERBEROS_VERSION $new_version
    if [ "$?" = "0" ];then
        echo -e "kerberos version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "kerberos current version: \033[0;33m${KERBEROS_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_sqlite_version()
function check_sqlite_version()
{
    # check_github_soft_version sqlite $SQLITE_VERSION "https://github.com/mackyle/sqlite/releases" "version-\([0-9.]\{5,\}\)\.tar\.gz" 1
    local new_version=`curl -k https://www.sqlite.org/download.html 2>/dev/null |sed -n 's/^.\{1,\}\/sqlite-autoconf-\([0-9.]\{1,\}\).tar.gz.\{1,\}$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测sqlite新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $SQLITE_VERSION $new_version
    if [ "$?" = "0" ];then
        echo -e "sqlite version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "sqlite current version: \033[0;33m${SQLITE_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_imap_version()
function check_imap_version()
{
    local new_version=`curl -k https://www.mirrorservice.org/sites/ftp.cac.washington.edu/imap/ 2>/dev/null |sed -n 's/^.\{1,\}>imap-\([0-9a-zA-Z.-]\{1,\}\).tar.gz<.\{1,\}$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测imap新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $IMAP_VERSION $new_version
    if [ "$?" = "0" ];then
        echo -e "imap version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "imap current version: \033[0;33m${IMAP_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_libmemcached_version()
function check_libmemcached_version()
{
    local new_version=`curl -k "https://launchpad.net/libmemcached/+download" 2>/dev/null |sed -n 's/^.*>libmemcached-\([0-9.-]\{1,\}\).tar.gz<.*$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测libmemcached新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $LIBMEMCACHED_VERSION $new_version
    if [ "$?" = "0" ];then
        echo -e "libmemcached version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "libmemcached current version: \033[0;33m${LIBMEMCACHED_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_qrencode_version()
function check_qrencode_version()
{
    local new_version=`curl -k https://fukuchi.org/works/qrencode/ 2>/dev/null |sed -n 's/^.*>qrencode-\([0-9.-]\{1,\}\).tar.gz<.*$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测qrencode新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $LIBQRENCODE_VERSION $new_version
    if [ "$?" = "0" ];then
        echo -e "qrencode version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "qrencode current version: \033[0;33m${LIBQRENCODE_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_jpeg_version()
function check_jpeg_version()
{
    local new_version=`curl -k http://www.ijg.org/files/ 2>/dev/null |sed -n 's/^.*>jpegsrc\.v\([0-9a-zA-Z.]\{1,\}\).tar.gz<.*$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测jpeg新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $JPEG_VERSION $new_version
    if [ "$?" = "0" ];then
        echo -e "jpeg version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "jpeg current version: \033[0;33m${JPEG_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_pecl_sphinx_version()
function check_pecl_sphinx_version()
{
    # check_github_soft_version "pecl-search_engine-sphinx" $PHP_SPHINX_VERSION "https://github.com/php/pecl-search_engine-sphinx/releases"
    check_php_pecl_version sphinx $PHP_SPHINX_VERSION
}
# }}}
# {{{ function check_libxml2_version()
function check_libxml2_version()
{
    check_ftp_xmlsoft_org_version libxml2 ${LIBXML2_VERSION}
}
# }}}
# {{{ function check_libxslt_version()
function check_libxslt_version()
{
    check_ftp_xmlsoft_org_version libxslt ${LIBXSLT_VERSION}
}
# }}}
# {{{ function check_boost_version()
function check_boost_version()
{
    check_sourceforge_soft_version boost ${BOOST_VERSION//_/.} 's/^.\{0,\}<tr title="\([0-9.]\{1,\}\)" class="folder \{0,\}"> \{0,\}$/\1/p'
}
# }}}
# {{{ function check_libmcrypt_version()
function check_libmcrypt_version()
{
    check_sourceforge_soft_version mcrypt ${LIBMCRYPT_VERSION//_/.} 's/^.\{0,\}<tr title="\([0-9.]\{1,\}\)" class="folder \{0,\}"> \{0,\}$/\1/p' Libmcrypt
}
# }}}
# {{{ function check_libjpeg_version()
function check_libjpeg_version()
{
    check_sourceforge_soft_version libjpeg-turbo ${LIBJPEG_VERSION} 's/^.\{0,\}<tr title="\([0-9.]\{1,\}\)" class="folder \{0,\}"> \{0,\}$/\1/p' "0"
}
# }}}
# {{{ function check_pcre_version()
function check_pcre_version()
{
    check_sourceforge_soft_version pcre ${PCRE_VERSION//_/.} 's/^.\{0,\}<tr title="\([0-9.]\{1,\}\)" class="folder \{0,\}"> \{0,\}$/\1/p'
    check_sourceforge_soft_version pcre ${PCRE_VERSION//_/.} 's/^.\{0,\}<tr title="\([0-9.]\{1,\}\)" class="folder \{0,\}"> \{0,\}$/\1/p' pcre2
}
# }}}
# {{{ function check_expat_version()
function check_expat_version()
{
    check_sourceforge_soft_version expat ${EXPAT_VERSION} 's/^.\{0,\}<tr title="\([0-9.]\{1,\}\)" class="folder \{0,\}"> \{0,\}$/\1/p'
}
# }}}
# {{{ function check_libXpm_version()
function check_libXpm_version()
{
    check_freedesktop_soft_version libXpm ${LIBXPM_VERSION} https://www.x.org/releases/individual/lib/
}
# }}}
# {{{ function check_kbproto_version()
function check_kbproto_version()
{
    check_freedesktop_soft_version kbproto ${KBPROTO_VERSION} https://www.x.org/archive/individual/proto/
}
# }}}
# {{{ function check_inputproto_version()
function check_inputproto_version()
{
    check_freedesktop_soft_version inputproto ${INPUTPROTO_VERSION} https://www.x.org/archive/individual/proto/
}
# }}}
# {{{ function check_xextproto_version()
function check_xextproto_version()
{
    check_freedesktop_soft_version xextproto ${XEXTPROTO_VERSION} https://www.x.org/archive/individual/proto/
}
# }}}
# {{{ function check_xproto_version()
function check_xproto_version()
{
    check_freedesktop_soft_version xproto ${XPROTO_VERSION} https://www.x.org/archive/individual/proto/
}
# }}}
# {{{ function check_xtrans_version()
function check_xtrans_version()
{
    check_freedesktop_soft_version xtrans ${XTRANS_VERSION} https://www.x.org/archive/individual/lib/
}
# }}}
# {{{ function check_libXau_version()
function check_libXau_version()
{
    check_freedesktop_soft_version libXau ${LIBXAU_VERSION} https://www.x.org/archive/individual/lib/
}
# }}}
# {{{ function check_libX11_version()
function check_libX11_version()
{
    check_freedesktop_soft_version libX11 ${LIBX11_VERSION} https://www.x.org/archive/individual/lib/
}
# }}}
# {{{ function check_libpthread_stubs_version()
function check_libpthread_stubs_version()
{
    check_freedesktop_soft_version libpthread-stubs ${LIBPTHREAD_STUBS_VERSION} https://www.x.org/archive/individual/xcb/
}
# }}}
# {{{ function check_libxcb_version()
function check_libxcb_version()
{
    check_freedesktop_soft_version libxcb ${LIBXCB_VERSION} https://www.x.org/archive/individual/xcb/
}
# }}}
# {{{ function check_xcb_proto_version()
function check_xcb_proto_version()
{
    check_freedesktop_soft_version xcb-proto ${XCB_PROTO_VERSION} https://www.x.org/archive/individual/xcb/
}
# }}}
# {{{ function check_macros_version()
function check_macros_version()
{
    check_freedesktop_soft_version util-macros ${MACROS_VERSION} https://www.x.org/archive/individual/util/
}
# }}}
# {{{ function check_xf86bigfontproto_version()
function check_xf86bigfontproto_version()
{
    check_freedesktop_soft_version xf86bigfontproto ${XF86BIGFONTPROTO_VERSION} https://www.x.org/archive/individual/proto/
}
# }}}
# {{{ function check_cairo_version()
function check_cairo_version()
{
    check_ftp_version cairo ${CAIRO_VERSION} http://cairographics.org/releases/
}
# }}}
# {{{ function check_pixman_version()
function check_pixman_version()
{
    check_ftp_version pixman ${PIXMAN_VERSION} http://cairographics.org/releases/
}
# }}}
# {{{ function check_fontconfig_version()
function check_fontconfig_version()
{
    check_ftp_version fontconfig ${FONTCONFIG_VERSION} https://www.freedesktop.org/software/fontconfig/release/
}
# }}}
# {{{ function check_poppler_version()
function check_poppler_version()
{
    check_ftp_version poppler ${POPPLER_VERSION} https://poppler.freedesktop.org/ 's/^.\{1,\}>poppler-\([0-9.]\{1,\}\)\.tar\.xz<.\{0,\}$/\1/p'
}
# }}}
# {{{ function check_pango_version()
function check_pango_version()
{
    local tmpdir=`curl -Lk http://ftp.gnome.org/pub/GNOME/sources/pango/ 2>/dev/null|sed -n 's/^.*>\([0-9.-]\{1,\}\)\/<.*$/\1/p'|sort -rV | head -1`;
    if [ -z "$tmpdir" ];then
        echo -e "探测pango的新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi
    check_ftp_version pango ${PANGO_VERSION} http://ftp.gnome.org/pub/GNOME/sources/pango/${tmpdir}/ 's/^.\{1,\}>pango-\([0-9.]\{1,\}\)\.tar\.xz<.\{0,\}$/\1/p'
}
# }}}
# {{{ function check_libsodium_version()
function check_libsodium_version()
{
    check_ftp_version libsodium ${LIBSODIUM_VERSION} https://download.libsodium.org/libsodium/releases/
}
# }}}
# {{{ function check_memcached_version()
function check_memcached_version()
{
    check_ftp_version memcached ${MEMCACHED_VERSION} http://memcached.org/files/
}
# }}}
# {{{ function check_apache_version()
function check_apache_version()
{
    check_ftp_version httpd ${APACHE_VERSION} http://archive.apache.org/dist/httpd/
}
# }}}
# {{{ function check_apr_version()
function check_apr_version()
{
    check_ftp_version apr ${APR_VERSION} http://apr.apache.org/download.cgi
}
# }}}
# {{{ function check_apr_util_version()
function check_apr_util_version()
{
    check_ftp_version apr-util ${APR_UTIL_VERSION} http://apr.apache.org/download.cgi
}
# }}}
# {{{ function check_postgresql_version()
function check_postgresql_version()
{
    local tmpdir=`curl -Lk https://ftp.postgresql.org/pub/source/ 2>/dev/null|sed -n 's/^.*>v\([0-9.-]\{1,\}\)<.*$/\1/p'|sort -rV | head -1`;
    if [ -z "$tmpdir" ];then
        echo -e "探测postgresql的新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi
    check_ftp_version postgresql ${POSTGRESQL_VERSION} https://ftp.postgresql.org/pub/source/v${tmpdir}/
}
# }}}
# {{{ function check_ftp_gnu_org_version()
function check_ftp_gnu_org_version()
{
    local soft=$1
    local current_version=$2
    local url="http://ftp.gnu.org/gnu/${soft}/"
    local pattern=$3

    check_ftp_version $soft $current_version $url $pattern
}
# }}}
# {{{ function check_ftp_xmlsoft_org_version()
function check_ftp_xmlsoft_org_version()
{
    local soft=$1
    local current_version=$2
    local url="ftp://xmlsoft.org/${soft}/"
    local pattern=$3

    check_ftp_version $soft $current_version $url $pattern
}
# }}}
# {{{ function check_ftp_version()
function check_ftp_version()
{
    local soft=$1
    local current_version=$2
    local url=$3
    local pattern=$4

    if [ -z "$pattern" ]; then
        pattern="s/^.\{1,\}[> ]${soft}-\([0-9.]\{1,\}\)\.tar\.gz[< ]*.\{0,\}$/\1/p"
    fi

    local new_version=`curl -Lk "${url}" 2>/dev/null |sed -n "$pattern"|sort -urV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测${soft}新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $current_version $new_version
    if [ "$?" = "0" ];then
        echo -e "${soft} version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "${soft} current version: \033[0;33m${current_version}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_github_soft_version()
function check_github_soft_version()
{
    local soft=$1;
    local current_version=$2;
    local url=$3;
    local pattern="$4";
    local num="$5"

    if [ "$pattern" = "" ];then
                                                               # release\|beta
        pattern="\(RELEASE_\)\{0,1\}v\{0,1\}\([0-9._]\{1,\}\)\(-\(release\)\)\{0,1\}.tar.gz"
        num=2
    fi

    if [ "$num" = "" -o `echo "$num" |sed -n '/^[0-9]$/p'` != "$num" ];then
        num=2;
    fi

    pattern="s/^.\{1,\} href=\"[^\\\"]\{1,\}${soft}[^\\\"]\{0,\}\/archive\/$pattern\"[^>]\{0,\}>.\{0,\}$/\\${num}/p";

    local versions=`curl -k $url 2>/dev/null |sed -n "$pattern" |sort -rV`
    local new_version=`echo "$versions"|head -1`;

    if [ -z "$new_version" ];then
        echo -e "Check ${soft} version \033[0;31mfaild\033[0m." >&2
        return 1;
    fi

    echo "$new_version" |grep -iq 'RC'
    if [ "$?" = "0" ]; then
        local tmp_version1=`echo "$versions"|grep -iv 'RC' |head -1`;
        local tmp_version2=`echo "$new_version"|sed -n 's/^\([0-9._-]\{1,\}\)\([Rr][Cc]\).\{1,\}$/\1/p'`;
        if [ "$tmp_version1" = "$tmp_version2" ];then
            new_version=$tmp_version2;
        fi
    fi

    if [ "$current_version" = "php7" -o "$current_version" = "master" ];then
        if [ "$soft" = "pecl-search_engine-sphinx" ];then
            if [ "$new_version" = "1_3_3" ];then
                echo -e "${soft} version is \033[0;32mthe latest.\033[0m"
                return;
            else
                echo -e "${soft} current version: \033[0;33m${current_version}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
                return;
            fi
        elif [ "$soft" = "php-memcached" ];then
            if [ "$new_version" = "2.2.0" ];then
                echo -e "${soft} version is \033[0;32mthe latest.\033[0m"
                return;
            else
                echo -e "${soft} current version: \033[0;33m${current_version}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
                return;
            fi
        elif [ "$soft" = "php-zmq" ];then
            if [ "$new_version" = "1.1.2" ];then
                echo -e "${soft} version is \033[0;32mthe latest.\033[0m"
                return;
            else
                echo -e "${soft} current version: \033[0;33m${current_version}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
                return;
            fi
        else
            echo -e "${soft} current version: \033[0;33m${current_version}\033[0m\tDetect version: \033[0;35m${new_version}\033[0m. \033[41;37m未指定最后版本\033[0m"
            return;
        fi
    fi

    is_new_version $current_version $new_version
    if [ "$?" = "0" ];then
        echo -e "${soft} version is \033[0;32mthe latest.\033[0m"
        return 0;
    elif [ "$?" = "11" ] ; then
        return;
    fi

    echo -e "${soft} current version: \033[0;33m${current_version}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_php_pecl_version()
function check_php_pecl_version()
{
    local ext=$1;
    local current_version=$2;

    local versions=`curl -k http://pecl.php.net/package/${ext} 2>/dev/null|sed -n "s/^.\{1,\} href=\"\/get\/${ext}-\([0-9._]\{1,\}\(\(RC\)\{0,1\}[0-9]\{1,\}\)\{0,1\}\).tgz\"[^>]\{0,\}>.\{0,\}$/\1/p"|sort -rV`;
    local new_version=`echo "$versions"|head -1`;

    if [ -z "$new_version" -o -z "$current_version" ];then
        echo -e "chekc php pecl ${ext} version \033[0;31mfaild\033[0m." >&2
        return 1;
    fi

    echo "$new_version" |grep -iq 'RC'
    if [ "$?" = "0" ]; then
        local tmp_version1=`echo "$versions"|grep -iv 'RC' |head -1`;
        local tmp_version2=`echo "$new_version"|sed -n 's/^\([0-9._-]\{1,\}\)\([Rr][Cc]\).\{1,\}$/\1/p'`;
        if [ "$tmp_version1" = "$tmp_version2" ];then
            new_version=$tmp_version2;
        fi
    fi

    if [ "$current_version" = "php7" ];then
        if [ "$ext" = "sphinx" ];then
            if [ "$new_version" = "1.3.3" ];then
                echo -e "PHP extension ${ext} version is \033[0;32mthe latest.\033[0m"
                return;
            else
                echo -e "PHP extension ${ext} current version: \033[0;33m${current_version}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
                return;
            fi
        elif [ "$ext" = "memcached" ];then
            if [ "$new_version" = "2.2.0" ];then
                echo -e "PHP extension ${ext} version is \033[0;32mthe latest.\033[0m"
                return;
            else
                echo -e "PHP extension ${ext} current version: \033[0;33m${current_version}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
                return;
            fi
        else
            echo -e "PHP extension ${ext} current version: \033[0;33m${current_version}\033[0m\tDetect version: \033[0;35m${new_version}\033[0m. \033[41;37m未指定最后版本\033[0m"
            return;
        fi
    fi

    is_new_version $current_version $new_version
    if [ "$?" = "0" ];then
        echo -e "PHP extension ${ext} version is \033[0;32mthe latest.\033[0m"
        return 0;
    elif [ "$?" = "11" ] ; then
        return;
    fi

    echo -e "PHP extension ${ext} current version: \033[0;33m${current_version}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_sourceforge_soft_version()
function check_sourceforge_soft_version()
{
    local soft=$1
    local current_version=$2
    local pattern=$3
    local soft1=$soft

    if [ ! -z "$4" ];then
        soft1="$4"
    fi

    if [ -z "$pattern" ]; then
        pattern="s/^.\{1,\}Download \{1,\}${soft}-\([0-9.]\{1,\}\).tar\..\{1,\}$/\1/p"
    fi
    local new_version=`curl -Lk https://sourceforge.net/projects/${soft}/files/$( [ "${soft1}" = "0" ] || echo "${soft1}/" ) 2>/dev/null|sed -n "$pattern"|sort -rV|head -1`;
     if [ -z "$new_version" ];then
         echo -e "探测${soft}的新版本\033[0;31m失败\033[0m" >&2
         return 1;
     fi

     is_new_version $current_version $new_version
     if [ "$?" = "0" ];then
         echo -e "${soft} version is \033[0;32mthe latest.\033[0m"
         return 0;
     elif [ "$?" = "11" ] ; then
         return;
     fi

     echo -e "${soft} current version: \033[0;33m${current_version}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_freedesktop_soft_version()
function check_freedesktop_soft_version()
{
    local soft=$1
    local current_version=$2
    local url=$3
    local pattern=$4

    if [ -z "$pattern" ]; then
        pattern="s/^.*>${soft}-\([0-9.]\{1,\}\)\.tar\.gz<.*$/\1/p"
    fi
    local new_version=`curl -Lk $url 2>/dev/null|sed -n "$pattern"|sort -rV|head -1`;
     if [ -z "$new_version" ];then
         echo -e "探测${soft}的新版本\033[0;31m失败\033[0m" >&2
         return 1;
     fi

     is_new_version $current_version $new_version
     if [ "$?" = "0" ];then
         echo -e "${soft} version is \033[0;32mthe latest.\033[0m"
         return 0;
     elif [ "$?" = "11" ] ; then
         return;
     fi

     echo -e "${soft} current version: \033[0;33m${current_version}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
#}}}
# {{{ function version_compare() 11出错误 0 相同 1 前高于后 2 前低于后
function version_compare()
{
    local first_version=$1;
    local second_version=$2;

    if [ -z "$first_version" -o -z "$second_version" ]; then
        echo "parameter error. first_version: ${first_version} second_version: ${second_version}" >&2
        return 11;
    fi

    if [ "$first_version" = "$second_version" ];then
        return 0;
    fi

    local tmp_version=`echo "$first_version" "$second_version"|tr " " "\n"|sort -rV|head -1`;
    if [ -z "$tmp_version" ]; then
        echo "parameter error. first_version: ${first_version} second_version: ${second_version}" >&2
        return 11;
    fi
    if [ "$tmp_version" = "$first_version" ];then
        return 1;
    elif [ "$tmp_version" = "$second_version" ];then
        return 2;
    else
        echo "parameter error. first_version: ${first_version} second_version: ${second_version}" >&2
        return 11;
    fi

    return 2;
}
# }}}
# {{{ function is_new_version() 返回值0，为是新版本, 11 出错
function is_new_version()
{
    local new_version=$1;
    local old_version=$2;

    if [ -z "$new_version" -o -z "$old_version" ]; then
        echo "parameter error. new_version: ${new_version} old_version: ${old_version}" >&2
        return 11;
    fi

    if [ "$new_version" = "$old_version" ];then
        return 0;
    fi

    echo "$old_version" |grep -iq 'RC'
    local old_has_rc="$?"
    echo "$new_version" |grep -iq 'RC'
    local new_has_rc="$?"
    if [ "$old_has_rc" = "0" ]; then
        if [ "$new_has_rc" != "0" ]; then
            local tmp_version_old=`echo "$old_version"|sed -n 's/^\([0-9._-]\{1,\}\)\([Rr][Cc]\).\{1,\}$/\1/p'`;
            if [ "$tmp_version_old" = "$new_version" ];then
                return 0;
            fi
        fi
    elif [ "$new_has_rc" = "0" ]; then
        local tmp_version_new=`echo "$new_version"|sed -n 's/^\([0-9._-]\{1,\}\)\([Rr][Cc]\).\{1,\}$/\1/p'`;
        if [ "$tmp_version_new" = "$old_version" ];then
            return 1;
        fi
    fi

    local tmp_version=`echo "$new_version" "$old_version"|tr " " "\n"|sort -rV|head -1`;

    if [ -z "$tmp_version" ]; then
        echo "parameter error. new_version: ${new_version} old_version: ${old_version}" >&2
        return 11;
    fi

    if [ "$tmp_version" = "$new_version" ];then
        return 0;
    elif [ "$tmp_version" = "$old_version" ];then
        return 1;
    else
        echo "parameter error. new_version: ${new_version} old_version: ${old_version}" >&2
        return 11;
    fi

#    echo $new_version | grep -q  '^[0-9.]\{1,\}$'
#
#    if [ "$?" != 0 ]; then
#        echo "The version number format does not support." >&2
#        return 11;
#    fi
#
#    echo $old_version | grep -q  '^[0-9.]\{1,\}$'
#
#    if [ "$?" != 0 ]; then
#        echo "The version number format does not support." >&2
#        return 11;
#    fi
#
#    local new_version_vars=( ${new_version//./ } )
#    local old_version_vars=( ${old_version//./ } )
#
#    if [ "${#new_version_vars[*]}" -ne "${#old_version_vars[@]}" ]; then
#        echo "The version number format does not match. new_version: ${new_version} old_version: ${old_version}" >&2
#        return 11;
#    fi
#
#    local i=0;
#    for ((;i<${#old_version_vars[@]};i++))
#    {
#        if [ "${old_version_vars[i]}"  -lt "${new_version_vars[i]}" ]; then
#            return 0;
#        elif [ "${old_version_vars[i]}"  -gt "${new_version_vars[i]}" ]; then
#            echo "Warning: The version number error. new_version: ${new_version} old_version: ${old_version}" >&2
#            return 11;
#        fi
#    }
#
#    return 1;
}
# }}}
# {{{ function pkg_config_path_init()

function pkg_config_path_init()
{
    ld_library_path_init
    path_init

    which pkg-config > /dev/null 2>&1;
    if [ "$?" = "1" ];then
        compile_pkgconfig
    else
        export PKG_CONFIG=`which pkg-config`;
    fi

    local tmp_arr=( "/usr/lib64/pkgconfig" "/usr/share/pkgconfig" "/usr/lib/pkgconfig" "/usr/local/lib/pkgconfig" );
    local i=""
    for i in ${tmp_arr[@]}; do
    {
        if [ -d "$i" ];then
            export PKG_CONFIG_PATH="$i:$PKG_CONFIG_PATH";
        fi
    }
    done

    export PKG_CONFIG_PATH=${PKG_CONFIG_PATH%:}
    #PKG_CONFIG_PATH="$CONTRIB_BASE/lib/pkgconfig:$CONTRIB_BASE/share/pkgconfig:$PKG_CONFIG_PATH"
}
# }}}
# {{{ function deal_pkg_config_path()
function deal_pkg_config_path()
{
    local i="";
    local j="";
    for i in "$@"
    do
        if [ -z "$i" ] || [ ! -d $i ]; then
            echo "ERROR: deal_pkg_config_path parameter error. value: $i" >&2
            return 1;
        fi
        for j in `find $i -mindepth 0 -maxdepth 2 -name pkgconfig -type d`;
        do
            echo ${PKG_CONFIG_PATH}: |grep -q "$j:";
            if [ "$?" != 0 ];then
                export PKG_CONFIG_PATH="$j:$PKG_CONFIG_PATH"
            fi
        done
    done

    if [ "$j" = "" ];then
        # echo "ERROR: deal_pkg_config_path parameter error. value: $*  dir is not find pkgconfig dir." >&2
        return 0;
        #return 1;
    fi
}
# }}}
# {{{ function ld_library_path_init()

function ld_library_path_init()
{
    local tmp_arr=( "/usr/lib" "/usr/lib64" "/usr/local/lib" "/usr/local/lib64" );
    local i=""
    for i in ${tmp_arr[@]}; do
    {
        if [ -d "$i" ];then
            LD_LIBRARY_PATH="$i:$LD_LIBRARY_PATH";
        fi
    }
    done

    LD_LIBRARY_PATH=${LD_LIBRARY_PATH%:}
}
# }}}
# {{{ function deal_ld_library_path()
function deal_ld_library_path()
{
    local i="";
    local j="";
    for i in "$@"
    do
        if [ -z "$i" ] || [ ! -d $i ]; then
            echo "ERROR: deal_ld_library_path parameter error. value: $i" >&2
            return 1;
        fi
        for j in `find $i -mindepth 0 -maxdepth 1 -a \( -name lib -o -name lib64 \) -type d`;
        do
            echo ${LD_LIBRARY_PATH}: |grep -q "$j:";
            if [ "$?" != 0 ];then
                LD_LIBRARY_PATH="$j:$LD_LIBRARY_PATH"
            fi
        done
    done

    if [ "$j" = "" ];then
        # echo "ERROR: deal_ld_library_path parameter error. value: $*  dir is not find pkgconfig dir." >&2
        return 0;
        #return 1;
    fi
}
# }}}
# {{{ function path_init()

function path_init()
{
    PATH=""
    local tmp_arr=( "/bin"
            "/usr/bin"
            "/usr/sbin"
            "/usr/local/bin"
            "/usr/sbin"
            "/usr/local/opt/bison/bin"
            "/usr/local/opt/coreutils/libexec/gnubin"
            );
    local i=""
    for i in ${tmp_arr[@]}; do
    {
        if [ -d "$i" ];then
            PATH="$i:$PATH";
        fi
    }
    done

    PATH=${PATH%:}
    export PATH
}
# }}}
# {{{ function deal_path()
function deal_path()
{
    local i="";
    local j="";
    for i in "$@"
    do
        if [ -z "$i" ] || [ ! -d $i ]; then
            echo "ERROR: deal_path parameter error. value: $i" >&2
            return 1;
        fi
        for j in `find $i -mindepth 0 -maxdepth 1 -a \( -name bin -o -name sbin \) -type d`;
        do
            echo ${PATH}: |grep -q "$j:";
            if [ "$?" != 0 ];then
                PATH="$j:$PATH"
            fi
        done
    done

    export PATH

    if [ "$j" = "" ];then
        # echo "ERROR: deal_path parameter error. value: $*  dir is not find bin dir." >&2
        return 0;
        #return 1;
    fi
}
# }}}
# {{{ function export_path()
function export_path()
{
    export PATH="$COMPILE_BASE/bin:$CONTRIB_BASE/bin:$PATH"
}
# }}}
# {{{ function repair_dynamic_shared_library() mac下解决Library not loaded 问题
function repair_dynamic_shared_library()
{
    if [ "$OS_NAME" != "Darwin" ];then
        echo "this funtion[repair_dynamic_shared_library] not support  current OS[$OS_NAME]." >&2
        return;
    fi

    local dir1="$1"
    local filepattern="$2"
    local i=""
    local j=""
    for i in `find ${dir1} $( [ "$filepattern" != "" ] && echo "-name $filepattern" || echo "-type f")`;
    do
    {
        # 跳过软链接
        if [ -L $i ]; then
            continue;
        fi
        local filename="${i##*/}"
        for j in `otool -L $i|awk '{print $1; }' |grep -v '^/'`;
        do
        {
            local filename1="${j##*/}"
            if [ "$filename" = "${filename1}" ];then
                if [ "${i%%/*}" != "" ];then
                    echo "file not is absolute path. file: $i " >&2
                    return 1;
                fi
                install_name_tool -id $i $i;
                if [ "$?" != "0" ];then
                    return 1;
                fi
            else
                local num=`find $BASE_DIR -name ${filename1} |wc -l`;
                if [ "$num" = "0" ];then
                    echo "cant find file. filename: $j    file: $i" >&2 
                    return;
                elif [ "$num" != "1" ];then
                    echo "find more file with the same name. filename: $j  file: $i" >&2
                fi
                local f=`find $BASE_DIR -name ${filename1}`;
                install_name_tool -change  $j $f $i ;
                if [ "$?" != "0" ];then
                    return 1;
                fi
            fi
        }
        done
    }
    done
}
# }}}
function pthreads () {
    local task_name=$1
    local func_name=$2
    local thread_num=$3
    local params_name=$4

    thread_num=5  # 最大可同时执行线程数量
    job_num=100   # 任务总数


    tmp_fifofile="/tmp/${task_name}_$$.fifo";
    mkfifo $tmp_fifofile ;      # 新建一个fifo类型的文件
    exec 6<>$tmp_fifofile ;     # 将fd6指向fifo类型
    rm $tmp_fifofile ;   #删也可以


    #根据线程总数量设置令牌个数
    for ((i=0;i<${thread_num};i++));do
        echo
    done >&6

    for ((i=0;i<${job_num};i++));do # 任务数量
        # 一个read -u6命令执行一次，就从fd6中减去一个回车符，然后向下执行，
        # fd6中没有回车符的时候，就停在这了，从而实现了线程数量控制
        read -u6

        #可以把具体的需要执行的命令封装成一个函数
        {
            my_cmd $i
            echo >&6 # 当进程结束以后，再向fd6中加上一个回车符，即补上了read -u6减去的那个
        } &

    done

    wait
    exec 6>&- # 关闭fd6
    return;
}



#wget --content-disposition --no-check-certificate https://github.com/vrtadmin/clamav-devel/archive/clamav-0.99.2.tar.gz
#tar zxf clamav-devel-clamav-0.99.2.tar.gz
#cd clamav-devel-clamav-0.99.2
#./configure --prefix=/usr/local/chg/base/opt/clamav --with-openssl=$OPENSSL_BASE --with-pcre=$PCRE_BASE --with-zlib=$ZLIB_BASE --with-libbz2-prefix=/usr/local/chg/base/contrib --with-iconv --with-libcurl=$CURL_BASE
#./configure --prefix=/usr/local/chg/base/opt/clamav --with-openssl=$OPENSSL_BASE --with-pcre=$PCRE_BASE --with-zlib=$ZLIB_BASE --with-libbz2-prefix=/usr/local/chg/base/contrib --with-iconv --with-libcurl=$CURL_BASE --with-xml=$LIBXML2_BASE
#make
#make install
#cd ..
#rm -rf clamav-devel-clamav-0.99.2

#http://www.clamav.net/documents/installing-clamav

#https://linux.cn/article-5156-1.html
#https://github.com/argos66/php-clamav
#http://php-clamav.sourceforge.net/
#https://github.com/FileZ/php-clamd

#https://github.com/jonjomckay/quahog
#https://github.com/sunspikes/clamav-validator/blob/master/src/ClamavValidator/ClamavValidatorServiceProvider.php

# wget --content-disposition --no-check-certificate https://github.com/hprose/hprose-php/archive/v2.0.26.tar.gz
# wget --content-disposition --no-check-certificate https://github.com/hprose/hprose-swoole/archive/v2.0.11.tar.gz
#[chg@mail8 ~]$ ls hprose-php-2.0.26/src/
#functions.php  Hprose  Hprose.php  Throwable.php  TypeError.php

#[chg@mail8 ~]$ ls hprose-swoole-2.0.11/src/Hprose/Swoole/
#Client.php  Http  Server.php  Socket  Timer.php  WebSocket


#$CONTRIB_DIR/bin/mmdblookup --file $BASE_DIR/etc/geoip2/GeoLite2-Country.mmdb --ip 112.225.35.70
#$CONTRIB_DIR/bin/mmdblookup -f $BASE_DIR/etc/geoip2/GeoLite2-City.mmdb -i 118.194.236.35 city "zh-CN"
#$CONTRIB_DIR/bin/mmdblookup -f $BASE_DIR/etc/geoip2/GeoLite2-City.mmdb -i 112.124.127.64
#$CONTRIB_DIR/bin/mmdblookup -f $BASE_DIR/etc/geoip2/GeoLite2-City.mmdb -i 112.124.127.64 city names zh-CN


#IP数据库自动更新, 需要在crontab中设置
#$GEOIPUPDATE_BASE/bin/geoipupdate -h
#$GEOIPUPDATE_BASE/bin/geoipupdate -f $BASE_DIR/etc/GeoIP2_update.conf -d /tmp/ &

# 每周三5点更新 (GeoIP2、GeoIP旧版国家及城市以及GeoIP旧版区域数据库每周二更新。所有其他数据库在每个月的第一个周二更新)
# 时差
#0 5 * * 3 /usr/local/eyou/mail/opt/bin/geoipupdate >/dev/null 2>&1 &

# 问题，及解决方法
#libtoolize --quiet
#libtoolize: `COPYING.LIB' not found in `/usr/share/libtool/libltdl'
#yum install libtool-ltdl-devel

