#!/bin/bash

function check_minimum_env_requirements()
{
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
    is_finished_wget "$?/$FILE_NAME"
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

    if [ "$?" != 0 ];then
        exit 1;
    fi
}
# }}}}
# {{{ function function_exists() 检测函数是否定义
function function_exists()
{
    type "$1" 2>/dev/null|grep -q 'function'
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
    # wget_lib $JSON_FILE_NAME          "https://s3.amazonaws.com/json-c_releases/releases/$JSON_FILE_NAME"
    # http://sourceforge.net/projects/mcrypt/files/MCrypt/2.6.8/mcrypt-2.6.8.tar.gz/download
    wget_lib $LIBMCRYPT_FILE_NAME     "http://sourceforge.net/projects/mcrypt/files/Libmcrypt/$LIBMCRYPT_VERSION/$LIBMCRYPT_FILE_NAME/download"
    wget_lib $SQLITE_FILE_NAME        "http://www.sqlite.org/2016/$SQLITE_FILE_NAME"
    wget_lib $CURL_FILE_NAME          "http://curl.haxx.se/download/$CURL_FILE_NAME"
    # http://downloads.mysql.com/archives/mysql-${MYSQL_VERSION%.*}/$MYSQL_FILE_NAME
    # http://mysql.oss.eznetsols.org/Downloads/MySQL-${MYSQL_VERSION%.*}/$MYSQL_FILE_NAME
    wget_lib $MYSQL_FILE_NAME         "http://cdn.mysql.com/Downloads/MySQL-${MYSQL_VERSION%.*}/$MYSQL_FILE_NAME"
    wget_lib $BOOST_FILE_NAME         "https://sourceforge.net/projects/boost/files/boost/${BOOST_VERSION//_/.}/$BOOST_FILE_NAME/download"
    wget_lib $PCRE_FILE_NAME          "http://sourceforge.net/projects/pcre/files/pcre/$PCRE_VERSION/$PCRE_FILE_NAME/download"
    wget_lib $NGINX_FILE_NAME         "http://nginx.org/download/$NGINX_FILE_NAME"
    wget_lib $PHP_FILE_NAME           "http://cn2.php.net/distributions/$PHP_FILE_NAME"
    wget_lib $PTHREADS_FILE_NAME      "http://pecl.php.net/get/$PTHREADS_FILE_NAME"
    wget_lib $SWOOLE_FILE_NAME        "http://pecl.php.net/get/$SWOOLE_FILE_NAME"

    # wget_lib $LIBPNG_FILE_NAME     "https://sourceforge.net/projects/libpng/files/libpng$(echo ${LIBPNG_VERSION%\.*}|sed 's/\.//g')/$LIBPNG_VERSION/$LIBPNG_FILE_NAME/download"
    local version=${LIBPNG_VERSION%.*};
    wget_lib $LIBPNG_FILE_NAME        "https://sourceforge.net/projects/libpng/files/libpng${version/./}/$LIBPNG_VERSION/$LIBPNG_FILE_NAME/download"

    wget_lib $PIXMAN_FILE_NAME        "http://cairographics.org/releases/$PIXMAN_FILE_NAME"
    wget_lib $CAIRO_FILE_NAME         "http://cairographics.org/releases/$CAIRO_FILE_NAME"

    wget_lib $NASM_FILE_NAME          "http://www.nasm.us/pub/nasm/releasebuilds/$NASM_VERSION/$NASM_FILE_NAME"
    wget_lib $JPEG_FILE_NAME          "http://www.ijg.org/files/$JPEG_FILE_NAME"
    wget_lib $LIBJPEG_FILE_NAME       "https://sourceforge.net/projects/libjpeg-turbo/files/$LIBJPEG_VERSION/$LIBJPEG_FILE_NAME/download"

    wget_lib $OPENJPEG_FILE_NAME      "https://github.com/uclouvain/openjpeg/archive/version.${OPENJPEG_VERSION}.tar.gz"
    wget_lib $FREETYPE_FILE_NAME      "https://sourceforge.net/projects/freetype/files/freetype${FREETYPE_VERSION%%.*}/$FREETYPE_VERSION/$FREETYPE_FILE_NAME/download"
    wget_lib $EXPAT_FILE_NAME         "https://sourceforge.net/projects/expat/files/expat/$EXPAT_VERSION/$EXPAT_FILE_NAME/download"
    wget_lib $FONTCONFIG_FILE_NAME    "https://www.freedesktop.org/software/fontconfig/release/$FONTCONFIG_FILE_NAME"
    wget_lib $POPPLER_FILE_NAME       "https://poppler.freedesktop.org/$POPPLER_FILE_NAME"
    wget_lib $FONTFORGE_FILE_NAME     "https://github.com/fontforge/fontforge/archive/${FONTFORGE_VERSION}.tar.gz"
    wget_lib $PDF2HTMLEX_FILE_NAME    "https://github.com/coolwanglu/pdf2htmlEX/archive/v$PDF2HTMLEX_VERSION.tar.gz"
    wget_lib $PANGO_FILE_NAME         "http://ftp.gnome.org/pub/GNOME/sources/pango/${PANGO_VERSION%.*}/$PANGO_FILE_NAME"
    # wget_lib https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-1.2.7.tar.bz2
    wget_lib $LIBXPM_FILE_NAME        "http://xorg.freedesktop.org/releases/individual/lib/$LIBXPM_FILE_NAME"
    # wget_lib $LIBGD_FILE_NAME       "https://bitbucket.org/libgd/gd-libgd/downloads/$LIBGD_FILE_NAME"
    wget_lib $LIBGD_FILE_NAME         "http://fossies.org/linux/www/$LIBGD_FILE_NAME"
    wget_lib $IMAGEMAGICK_FILE_NAME  "https://sourceforge.net/projects/imagemagick/files/${IMAGEMAGICK_VERSION%-*}-sources/$IMAGEMAGICK_FILE_NAME/download"
    # wget_lib $IMAGEMAGICK_FILE_NAME   "http://www.imagemagick.org/download/$IMAGEMAGICK_FILE_NAME"
    wget_lib $GMP_FILE_NAME           "ftp://ftp.gmplib.org/pub/gmp/$GMP_FILE_NAME"
    wget_lib $IMAP_FILE_NAME          "ftp://ftp.cac.washington.edu/imap/$IMAP_FILE_NAME"
    wget_lib $KERBEROS_FILE_NAME      "http://web.mit.edu/kerberos/dist/krb5/${KERBEROS_VERSION%.*}/$KERBEROS_FILE_NAME"
    wget_lib $LIBMEMCACHED_FILE_NAME  "https://launchpad.net/libmemcached/${LIBMEMCACHED_VERSION%.*}/$LIBMEMCACHED_VERSION/+download/$LIBMEMCACHED_FILE_NAME"
    #  https://github.com/downloads/libevent/libevent/$LIBEVENT_FILE_NAME
    # wget_lib $LIBEVENT_FILE_NAME      "https://sourceforge.net/projects/levent/files//libevent-${LIBEVENT_VERSION%.*}/$LIBEVENT_FILE_NAME"
    wget_lib $LIBEVENT_FILE_NAME      "https://sourceforge.net/projects/levent/files/release-${LIBEVENT_VERSION}/$LIBEVENT_FILE_NAME/download"
    wget_lib $LIBQRENCODE_FILE_NAME   "http://fukuchi.org/works/qrencode/$LIBQRENCODE_FILE_NAME"
    wget_lib $POSTGRESQL_FILE_NAME    "https://ftp.postgresql.org/pub/source/v$POSTGRESQL_VERSION/$POSTGRESQL_FILE_NAME"
    wget_lib $APR_FILE_NAME           "http://mirrors.cnnic.cn/apache//apr/$APR_FILE_NAME"
    wget_lib $APR_UTIL_FILE_NAME      "http://mirror.bit.edu.cn/apache//apr/$APR_UTIL_FILE_NAME"
    # http://mirror.bjtu.edu.cn/apache/httpd/$APACHE_FILE_NAME
    wget_lib $APACHE_FILE_NAME        "http://archive.apache.org/dist/httpd/$APACHE_FILE_NAME"
    wget_lib $APCU_FILE_NAME          "http://pecl.php.net/get/$APCU_FILE_NAME"
    wget_lib $MEMCACHED_FILE_NAME     "http://pecl.php.net/get/$MEMCACHED_FILE_NAME"
    wget_lib $EVENT_FILE_NAME         "http://pecl.php.net/get/$EVENT_FILE_NAME"
    wget_lib $DIO_FILE_NAME           "http://pecl.php.net/get/$DIO_FILE_NAME"
    wget_lib $PHP_LIBEVENT_FILE_NAME  "http://pecl.php.net/get/$PHP_LIBEVENT_FILE_NAME"
    wget_lib $IMAGICK_FILE_NAME       "http://pecl.php.net/get/$IMAGICK_FILE_NAME"
    wget_lib $PHP_LIBSODIUM_FILE_NAME "http://pecl.php.net/get/$PHP_LIBSODIUM_FILE_NAME"
    wget_lib $QRENCODE_FILE_NAME      "https://codeload.github.com/dreamsxin/qrencodeforphp/tar.gz/master"
    wget_lib $ZEND_FILE_NAME          "https://packages.zendframework.com/releases/ZendFramework-$ZEND_VERSION/$ZEND_FILE_NAME"
    wget_lib $SMARTY_FILE_NAME        "https://github.com/smarty-php/smarty/archive/v$SMARTY_VERSION.tar.gz"
    wget_lib $CKEDITOR_FILE_NAME      "http://download.cksource.com/CKEditor/CKEditor/CKEditor%20$CKEDITOR_VERSION/$CKEDITOR_FILE_NAME"
    wget_lib $JQUERY_FILE_NAME        "http://code.jquery.com/$JQUERY_FILE_NAME"
    version=${ZEROMQ_VERSION%.*};
    # wget_lib $ZEROMQ_FILE_NAME        "https://github.com/zeromq/zeromq${version/./-}/releases/download/v${ZEROMQ_VERSION}/$ZEROMQ_FILE_NAME"
    wget_lib $ZEROMQ_FILE_NAME        "https://github.com/zeromq/${ZEROMQ_FILE_NAME%-*}/archive/v${ZEROMQ_VERSION}.tar.gz"
    wget_lib $LIBSODIUM_FILE_NAME     "https://download.libsodium.org/libsodium/releases/$LIBSODIUM_FILE_NAME"
    wget_lib $PHP_ZMQ_FILE_NAME       "https://github.com/mkoppanen/php-zmq/archive/${PHP_ZMQ_VERSION}.tar.gz"
    # wget_lib $SWFUPLOAD_FILE_NAME    "http://swfupload.googlecode.com/files/SWFUpload%20v$SWFUPLOAD_VERSION%20Core.zip"

    if [ "$os_name" = 'Darwin' ];then

        wget_lib $KBPROTO_FILE_NAME          "http://xorg.freedesktop.org/archive/individual/proto/$KBPROTO_FILE_NAME"
        wget_lib $INPUTPROTO_FILE_NAME       "http://xorg.freedesktop.org/archive/individual/proto/$INPUTPROTO_FILE_NAME"
        wget_lib $XEXTPROTO_FILE_NAME        "http://xorg.freedesktop.org/archive/individual/proto/$XEXTPROTO_FILE_NAME"
        wget_lib $XPROTO_FILE_NAME           "http://xorg.freedesktop.org/archive/individual/proto/$XPROTO_FILE_NAME"
        wget_lib $XTRANS_FILE_NAME           "http://xorg.freedesktop.org/archive/individual/lib/$XTRANS_FILE_NAME"
        wget_lib $LIBXAU_FILE_NAME           "http://xorg.freedesktop.org/archive/individual/lib/$LIBXAU_FILE_NAME"
        wget_lib $LIBX11_FILE_NAME           "http://xorg.freedesktop.org/archive/individual/lib/$LIBX11_FILE_NAME"
        wget_lib $LIBPTHREAD_STUBS_FILE_NAME "http://xorg.freedesktop.org/archive/individual/xcb/$LIBPTHREAD_STUBS_FILE_NAME"
        wget_lib $LIBXCB_FILE_NAME           "http://xorg.freedesktop.org/archive/individual/xcb/$LIBXCB_FILE_NAME"
        wget_lib $XCB_PROTO_FILE_NAME        "http://xorg.freedesktop.org/archive/individual/xcb/$XCB_PROTO_FILE_NAME"
        wget_lib $MACROS_FILE_NAME           "http://xorg.freedesktop.org/archive/individual/util/$MACROS_FILE_NAME"

    fi

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
    # sed -i.bak.$$ "s/\<MYSQL_BASE_DIR\>/$( echo $MYSQL_BASE|sed 's/\//\\\//g' )/" $NGINX_CONFIG_DIR/nginx.conf;

    # fastcgi_param  SERVER_SOFTWARE
    sed -i.bak.$$ "s/^\(fastcgi_param \{1,\}SERVER_SOFTWARE \{1,\}\)nginx\/\$nginx_version;$/\1eyou\/1.0;/" $NGINX_CONFIG_DIR/fastcgi.conf;
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

    $func

    if [ "$?" != "0" ];then
        return 1;
    fi

    deal_pkg_config_path "$2"

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
    local FILENAME="$OPENSSL_BASE/lib/pkgconfig/openssl.pc"
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
# {{{ function is_installed_libevent()
function is_installed_libevent()
{
    local FILENAME=$LIBEVENT_BASE/lib/pkgconfig/libevent.pc;
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
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
    if [ "${version}" != "$FREETYPE_VERSION" ];then
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
# {{{ function is_installed_xcb-proto()
function is_installed_xcb-proto()
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
# {{{ function is_installed_libpthread-stubs()
function is_installed_libpthread-stubs()
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
    echo "is_installed_imap Function not implemented ." >&2
    return 1;
    local FILENAME="$IMAP_BASE/lib/pkgconfig/imap.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$IMAP_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_kerberos()
function is_installed_kerberos()
{
    echo "is_installed_kerberos Function not implemented ." >&2
    return 1;
    local FILENAME="$KERBEROS_BASE/lib/pkgconfig/krb5.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
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
# {{{ function is_installed_apr-util()
function is_installed_apr-util()
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
    return;
}
# }}}
# {{{ function is_installed_php_extension()
function is_installed_php_extension()
{
    if [ ! -f "$PHP_BASE/bin/php" ];then
        return 1;
    fi

    $PHP_BASE/bin/php -m | grep -q $1
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
        return;
    fi

    PKGCONFIG_CONFIGURE="
    ./configure --prefix=$PKGCONFIG_BASE
    "
    #--with-internal-glib

    compile "pkg-config" "$PKGCONFIG_FILE_NAME" "pkg-config-$PKGCONFIG_VERSION" "$PKGCONFIG_BASE" "PKGCONFIG_CONFIGURE"
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
    ./configure --prefix=$PCRE_BASE
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

    ICU_CONFIGURE="
    ./configure --prefix=$ICU_BASE
    "

    compile "icu" "$ICU_FILE_NAME" "icu/source" "$ICU_BASE" "ICU_CONFIGURE"
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
    is_installed libzip "$LIBZIP_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    compile_zlib


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

    compile_libintl

    LIBICONV_CONFIGURE="
    ./configure --prefix=$LIBICONV_BASE \
                --with-libintl-prefix=$LIBINITL_BASE
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
    #--with-libintl-prefix \

    compile "gettext" "$GETTEXT_FILE_NAME" "gettext-$GETTEXT_VERSION" "$GETTEXT_BASE" "GETTEXT_CONFIGURE"
}
# }}}
# {{{ function compile_libxml2()
function compile_libxml2()
{
    is_installed libxml2 "$LIBXML2_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    compile_zlib
    compile_libiconv

    LIBXML2_CONFIGURE="
    ./configure --prefix=$LIBXML2_BASE \
                --with-iconv=$LIBICONV_BASE \
                --with-zlib=$ZLIB_BASE \
                --without-python
    "

    compile "libxml2" "$LIBXML2_FILE_NAME" "libxml2-$LIBXML2_VERSION" "$LIBXML2_BASE" "LIBXML2_CONFIGURE"
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

    compile "json-c" "$JSON_FILE_NAME" "json-c--$JSON_VERSION" "$JSON_BASE" "JSON_CONFIGURE"
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
    is_installed libevent "$LIBEVENT_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    compile_openssl

    #CPPFLAGS="-I$CONTRIB_BASE/include" LDFLAGS="-L$CONTRIB_BASE/lib$tmp_ldflags" \
    LIBEVENT_CONFIGURE="
    ./configure --prefix=$LIBEVENT_BASE
    "

    compile "libevent" "$LIBEVENT_FILE_NAME" "libevent-$LIBEVENT_VERSION" "$LIBEVENT_BASE" "LIBEVENT_CONFIGURE"
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
    is_installed libpng "$LIBPNG_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    compile_zlib

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
    ./configure --prefix=$SQLITE_BASE
    "

    compile "sqlite" "$SQLITE_FILE_NAME" "sqlite-autoconf-$SQLITE_VERSION" "$SQLITE_BASE" "SQLITE_CONFIGURE"
}
# }}}
# {{{ function compile_curl()
function compile_curl()
{
    is_installed curl "$CURL_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    compile_zlib
    compile_openssl

    CURL_CONFIGURE="
    ./configure --prefix=$CURL_BASE \
                --with-zlib=$ZLIB_BASE \
                --with-ssl=$OPENSSL_BASE
    "
    # --disable-debug --enable-optimize

    compile "curl" "$CURL_FILE_NAME" "curl-$CURL_VERSION" "$CURL_BASE" "CURL_CONFIGURE"
}
# }}}
# {{{ function compile_freetype()
function compile_freetype()
{
    is_installed freetype "$FREETYPE_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    compile_zlib
    compile_libpng

    FREETYPE_CONFIGURE="
    ./configure --prefix=$FREETYPE_BASE \
                --with-zlib=yes \
                --with-png=yes
    "
    #--with-bzip2=yes

    compile "freetype" "$FREETYPE_FILE_NAME" "freetype-$FREETYPE_VERSION" "$FREETYPE_BASE" "FREETYPE_CONFIGURE"
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
    is_installed macros "$MACROS_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    compile_xproto

    MACROS_CONFIGURE="
    ./configure --prefix=$MACROS_BASE
    "

    compile "util-macros" "$MACROS_FILE_NAME" "util-macros-$MACROS_VERSION" "$MACROS_BASE" "MACROS_CONFIGURE"
}
# }}}
# {{{ function compile_xcb-proto()
function compile_xcb-proto()
{
    is_installed xcb-proto "$XCB_PROTO_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    XCB_PROTO_CONFIGURE="
    ./configure --prefix=$XCB_PROTO_BASE
    "

    compile "xcb-proto" "$XCB_PROTO_FILE_NAME" "xcb-proto-$XCB_PROTO_VERSION" "$XCB_PROTO_BASE" "XCB_PROTO_CONFIGURE"
}
# }}}
# {{{ function compile_libpthread-stubs()
function compile_libpthread-stubs()
{
    is_installed libpthread-stubs "$LIBPTHREAD_STUBS_BASE"
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
# {{{ function compile_libX11()
function compile_libX11()
{
    is_installed libX11 "$LIBX11_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    compile_macros
    compile_xcb-proto
    compile_libpthread-stubs
    compile_libXau
    compile_libxcb
    compile_kbproto
    compile_inputproto
    compile_xextproto
    compile_xtrans

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
    is_installed libXpm "$LIBXPM_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    if [ "$os_name" = 'Darwin' ];then
        compile_libX11
        :
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
    is_installed fontconfig "$FONTCONFIG_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    compile_expat
    compile_freetype
    compile_libiconv
    compile_libxml2

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
    is_installed imap "$IMAP_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    IMAP_CONFIGURE="
    ./configure --prefix=$IMAP_BASE
    "

    compile "imap" "$IMAP_FILE_NAME" "imap-$IMAP_VERSION" "$IMAP_BASE" "IMAP_CONFIGURE"
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

    compile "kerberos" "$KERBEROS_FILE_NAME" "krb5-$KERBEROS_VERSION" "$KERBEROS_BASE" "KERBEROS_CONFIGURE"
}
# }}}
# {{{ function compile_libmemcached()
function compile_libmemcached()
{
    is_installed libmemcached "$LIBMEMCACHED_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

#解决以下问题：
#make[1]: *** [libmemcached/csl/libmemcached_libmemcached_la-context.lo] 错误 1
#make[1]: *** 正在等待未完成的任务….
#make[1]: *** [libmemcached/csl/libmemcached_libmemcached_la-parser.lo] 错误 1
#
#yum  install  gcc*
#CC="gcc44" CXX="g++44"

#if [ "$os_name" = 'Darwin' ];then
## 1.0.18编译不过去时的处理
#if [ "$LIBMEMCACHED_VERSION" = "1.0.18" ]; then
#
##在libmemcached/byteorder.cc的头部加上下面的代码即可：
#
###ifdef HAVE_SYS_TYPES_H
###include <sys/types.h>
###endif
##同时，将clients/memflush.cc里if (opt_servers == false)的代码替换成if (opt_servers == NULL)，一切就顺利了。
#
#
#sed -i.bak 's/if (opt_servers == false)/if (opt_servers == NULL)/g' clients/memflush.cc
#
#tmp_str=`sed -n '/#include/=' libmemcached/byteorder.cc`;
#line_num=`echo $tmp_str | sed -n 's/^.* \([0-9]\{1,\}\)$/\1/p'`;
#if [ "$tmp_str" != "" ] && [ "$line_num" != "" ];then
#    sed -i.bak "${line_num}a\\
#\\
##ifdef HAVE_SYS_TYPES_H \\
##include <sys/types.h> \\
##endif
#" libmemcached/byteorder.cc
#
#fi
#
#fi
#fi
    #gcc (GCC) 4.4.6 时没有问题
    #CC="gcc44" CXX="g++44"  \
    LIBMEMCACHED_CONFIGURE="
    ./configure --prefix=$LIBMEMCACHED_BASE
    "
                #--with-libevent=$LIBEVENT_BASE
                # --with-mysql=
                # --with-gearmand=
                # --with-memcached=

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
# {{{ function compile_apr-util()
function compile_apr-util()
{
    is_installed apr-util "$APR_UTIL_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    compile_openssl
    compile_libiconv
    compile_apr

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
    is_installed apache "$APACHE_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    compile_pcre
    compile_openssl
    compile_apr
    compile_apr-util

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
    ./configure --prefix=$NGINX_BASE \
                --conf-path=$NGINX_CONFIG_DIR/nginx.conf \
                --with-ipv6 \
                --with-threads \
                --with-http_ssl_module \
                --with-pcre=../pcre-$PCRE_VERSION \
                --with-zlib=../zlib-$ZLIB_VERSION \
                --with-openssl=../openssl-$OPENSSL_VERSION \
                --with-http_gunzip_module \
                --with-http_gzip_static_module
    "
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
# {{{ function compile_libgd()
function compile_libgd()
{
    is_installed libgd "$LIBGD_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    compile_zlib
    compile_libpng
    compile_freetype
    compile_fontconfig
    compile_jpeg
    # compile_libXpm

    # CPPFLAGS="-I$CONTRIB_BASE/include$( [ "$os_name" = 'Darwin' ] && echo " -I$LIBX11_BASE/include" )" LDFLAGS="-L$CONTRIB_BASE/lib$tmp_ldflags$( [ "$os_name" = 'Darwin' ] && echo " -I$LIBX11_BASE/lib" )" \
    LIBGD_CONFIGURE="
    ./configure --prefix=$LIBGD_BASE --with-libiconv-prefix=$LIBICONV_BASE \
                --with-zlib=$ZLIB_BASE \
                --with-png=$LIBPNG_BASE \
                --with-freetype=$FREETYPE_BASE \
                --with-fontconfig=$FONTCONFIG_BASE \
                --with-jpeg=$JPEG_BASE \
    "
#              --with-xpm=$LIBXPM_BASE
                # --with-vpx=
                # --with-tiff=

    compile "libgd" "$LIBGD_FILE_NAME" "libgd-$LIBGD_VERSION" "$LIBGD_BASE" "LIBGD_CONFIGURE"
}
# }}}
# {{{ function compile_ImageMagick()
function compile_ImageMagick()
{
    is_installed ImageMagick "$IMAGEMAGICK_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    IMAGEMAGICK_CONFIGURE="
    ./configure --prefix=$IMAGEMAGICK_BASE --enable-opencl
    "
                #--with-libstdc=/usr/local/Cellar/gcc/5.2.0

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
    ./configure --prefix=$LIBSODIUM_BASE
    "

    compile "libsodium" "$LIBSODIUM_FILE_NAME" "libsodium-$LIBSODIUM_VERSION" "$LIBSODIUM_BASE" "LIBSODIUM_CONFIGURE"
}
# }}}
# {{{ function compile_zeromq()
function compile_zeromq()
{
    is_installed zeromq "$ZEROMQ_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    # compile_libsodium

    ZEROMQ_CONFIGURE="
    configure_zeromq_command
    "
    # ./autogen.sh&&./configure --prefix=$ZEROMQ_BASE
    # --with-militant --with-libsodium --with-pgm  --with-norm

    compile "zeromq" "$ZEROMQ_FILE_NAME" "${ZEROMQ_FILE_NAME%-*}-$ZEROMQ_VERSION" "$ZEROMQ_BASE" "ZEROMQ_CONFIGURE"
}
# }}}
# {{{ function compile_php()
function compile_php()
{
    is_installed php "$PHP_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    compile_openssl
    compile_sqlite
    compile_zlib
    compile_libxml2
    compile_gettext
    compile_libiconv
    compile_libmcrypt
    compile_curl
    compile_gmp
#    compile_libgd
    compile_freetype
    compile_jpeg
    compile_libpng
#compile_libXpm

    # EXTRA_LIBS="-lresolv" \
    PHP_CONFIGURE="
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
                --without-regex \
                --enable-maintainer-zts \
                --with-gmp=$GMP_BASE \
                --enable-fpm \
                $( [ \"$os_name\" != \"Darwin\" ] && echo --with-fpm-acl ) \
                --enable-opcache
    "
#                --with-gd=$LIBGD_BASE \
#                --with-freetype-dir=$FREETYPE_BASE \
#                --enable-gd-native-ttf \
#                --with-jpeg-dir=$JPEG_BASE \
#                --with-png-dir=$LIBPNG_BASE \
#                --with-zlib-dir=$ZLIB_BASE \
#               --with-xpm-dir=$LIBXPM_BASE \

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

    compile "php" "$PHP_FILE_NAME" "php-$PHP_VERSION" "$PHP_BASE" "PHP_CONFIGURE" "after_php_make_install"

        #DYLD_FALLBACK_LIBRARY_PATH="$ICU_BASE/lib" #执行php --ini时报错，加载不上库文件，要这个变量
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
    is_installed_php_extension intl
    if [ "$?" = "0" ];then
        return;
    fi

    compile_icu

    PHP_EXTENSION_INTL_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --enable-intl --with-icu-dir=$ICU_BASE
    "
    compile "php_extension_intl" "$PHP_FILE_NAME" "php-$PHP_VERSION/ext/intl/" "intl.so" "PHP_EXTENSION_INTL_CONFIGURE"
}
# }}}
# {{{ function compile_php_extension_pdo_pgsql()
function compile_php_extension_pdo_pgsql()
{
    is_installed_php_extension pdo_pgsql
    if [ "$?" = "0" ];then
        return;
    fi

    compile_postgresql

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
    ./configure --with-php-config=$PHP_BASE/bin/php-config --enable-apcu --enable-apc-bc
    "
    compile "php_extension_apcu" "$APCU_FILE_NAME" "apcu-$APCU_VERSION" "apcu.so" "PHP_EXTENSION_APCU_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_memcached()
function compile_php_extension_memcached()
{
    is_installed_php_extension memcached
    if [ "$?" = "0" ];then
        return;
    fi

    compile_zlib
    compile_libmemcached

    PHP_EXTENSION_MEMCACHED_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --with-libmemcached-dir=$LIBMEMCACHED_BASE \
                --with-zlib-dir=$ZLIB_BASE
    "
                # --enable-memcached

    compile "php_extension_memcached" "$MEMCACHED_FILE_NAME" "memcached-$MEMCACHED_VERSION" "memcached.so" "PHP_EXTENSION_MEMCACHED_CONFIGURE"

    /bin/rm -rf package.xml
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

    compile "php_extension_pthreads" "$PTHREADS_FILE_NAME" "pthreads-$PTHREADS_VERSION" "pthreads.so" "PHP_EXTENSION_PTHREADS_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_swoole()
function compile_php_extension_swoole()
{
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
    is_installed_php_extension qrencode
    if [ "$?" = "0" ];then
        return;
    fi

    compile_qrencode

    PHP_EXTENSION_QRENCODE_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --with-qrencode=$LIBQRENCODE_BASE
    "

    # $PHP_BASE/bin/phpize --clean
    compile "php_extension_qrencode" "$QRENCODE_FILE_NAME" "qrencodeforphp-$QRENCODE_VERSION" "qrencode.so" "PHP_EXTENSION_QRENCODE_CONFIGURE"

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
    is_installed_php_extension event
    if [ "$?" = "0" ];then
        return;
    fi

    compile_openssl
    compile_libevent

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
    is_installed_php_extension libevent
    if [ "$?" = "0" ];then
        return;
    fi

    compile_libevent

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
    is_installed_php_extension imagick
    if [ "$?" = "0" ];then
        return;
    fi

    compile_ImageMagick

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
    is_installed_php_extension zmq
    if [ "$?" = "0" ];then
        return;
    fi

    compile_zeromq

    PHP_EXTENSION_ZEROMQ_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --with-zmq=/usr/local/chg/base/opt/zeromq --enable-zmq-pthreads
    "
                # --with-czmq=

    compile "php_extension_zeromq" "$PHP_ZMQ_FILE_NAME" "php-zmq-$PHP_ZMQ_VERSION" "zmq.so" "PHP_EXTENSION_ZEROMQ_CONFIGURE"
}
# }}}
# {{{ function compile_php_extension_libsodium()
function compile_php_extension_libsodium()
{
    is_installed_php_extension libsodium
    if [ "$?" = "0" ];then
        return;
    fi

    compile_libsodium

    PHP_EXTENSION_LIBSODIUM_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --with-libsodium=$LIBSODIUM_BASE
    "

    compile "php_extension_libsodium" "$PHP_LIBSODIUM_FILE_NAME" "libsodium-$PHP_LIBSODIUM_VERSION" "libsodium.so" "PHP_EXTENSION_LIBSODIUM_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_mysql()
function compile_mysql()
{

    is_installed mysql "$MYSQL_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    echo_build_start mysql

    compile_openssl

    decompress $MYSQL_FILE_NAME
    if [ "$?" != "0" ];then
        exit;
    fi
    decompress $BOOST_FILE_NAME
    if [ "$?" != "0" ];then
        exit;
    fi

    local boost_cmake_file="mysql-$MYSQL_VERSION/cmake/boost.cmake"
    if [ -f "$boost_cmake_file" ];then
        local version=`sed -n 's/^SET(BOOST_PACKAGE_NAME "boost_\(.\{1,\}\)")$/\1/p' $boost_cmake_file`
        if [ "$version" != "$BOOST_VERSION" ];then
            echo "Warning: BOOST VERSION ERROR: need $version, give $BOOST_VERSION" >&2
            exit 1;
        fi
    else
        echo "Warning: Can't find file: $boost_cmake_file" >&2
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
                                  -DWITH_SSL=$OPENSSL_BASE \
                                  -DWITH_BOOST=../boost_1_59_0/ \
                                  -DWITH_ZLIB=bundled \
                                  -DINSTALL_MYSQLTESTDIR=

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
    is_installed qrencode "$LIBQRENCODE_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    compile_libiconv

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
# {{{ configure command functions
# {{{ configure_zeromq_command()
configure_zeromq_command()
{
    ./autogen.sh \
    && \
    ./configure --prefix=$ZEROMQ_BASE
}
# }}}
# {{{ configure_php_swoole_command()
configure_php_swoole_command()
{
    #编译时如果没有pcre，使用时会有意想不到的结果 $memory_table->count() > 0，但是foreach 结果为空
    #yum install pcre.x86_64 pcre-devel.x86_64
    CPPFLAGS="-I$CONTRIB_BASE/include" LDFLAGS="-L$CONTRIB_BASE/lib$tmp_ldflags" \
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --enable-sockets \
                --enable-openssl \
                --with-swoole \
                --enable-swoole
}
# }}}
# }}}

# {{{ function compile_rabbitmq()
function compile_rabbitmq()
{
    echo "compile_rabbitmq 未完成" >&2
    return 1;
    is_installed rabbitmq
    if [ "$?" = "0" ];then
        return;
    fi

    compile_libiconv

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
    echo "compile_php_extension_rabbitmq 未完成" >&2
    return 1;
    is_installed_php_extension rabbitmq
    if [ "$?" = "0" ];then
        return;
    fi

    compile_rabbitmq

    PHP_EXTENSION_rabbitmq_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --with-librabbitmq-dir=$LIBRABBITMQ_BASE
    "

    compile "php_extension_rabbitmq" "$rabbitmq_FILE_NAME" "rabbitmq-$rabbitmq_VERSION" "rabbitmq.so" "PHP_EXTENSION_rabbitmq_CONFIGURE"

    /bin/rm -rf package.xml
#http://pecl.php.net/get/amqp-1.7.1.tgz
echo_build_start rabbitmq
tar zxf ""
cd
 $PHP_BASE/bin/phpize
 ./configure --with-php-config=$PHP_BASE/bin/php-config --with-librabbitmq-dir=$LIBRABBITMQ
make_run "$?/PHP rabbitmq"
if [ "$?" != "0" ];then
    exit 1;
fi
cd ..

/bin/rm -rf php-rabbitmq-$RABBITMQ_VERSION


other ....
 --with-wbxml=$WBXML_BASE
 --enable-http --with-http-curl-requests=$CURL_BASE --with-http-curl-libevent=$LIBEVENT_BASE --with-http-zlib-compression=$ZLIB_BASE --with-http-magic-mime=$MAGIC_BASE

}
# }}}
# {{{ function check_version()
function check_version()
{
    local func_name="check_$1_version";
    function_exists "$func_name";

    if [ "$?" != "0" ];
    then
        echo "$1的版本检测更新未实现"
        return 1;
    fi
}
# }}}
# {{{ function check_php_version()
function check_php_version()
{
    # local new_version=`curl http://php.net/downloads.php 2>/dev/null|sed -n 's/^.\{1,\}php-\([0-9.]\{1,\}\)\.tar\.xz.\{1,\}$/\1/p'|sed -n '1p'`
    local new_version=`curl http://php.net/downloads.php 2>/dev/null|sed -n '/^.\{1,\}php-\([0-9.]\{1,\}\)\.tar\.xz.\{1,\}$/{
    s//\1/p
    q
    }'`
    if [ -z "$new_version" ];then
        echo -e "探测php新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    version_compare $PHP_VERSION $new_version
    if [ "$?" !=0 ];then
        echo -e "PHP current version: \033[0;33m${PHP_VERSION}\033[0m\tserver's version: \033[0;35m${new_version}\033[0m"
    fi

    echo -e "PHP VERSION is \033[0;32mthe latest.\033[0m"
}
# }}}
# {{{ function check_imagemagick_version()
function check_imagemagick_version()
{
    local new_version=`curl http://www.imagemagick.org/download/ 2>/dev/null|sed -n '/^.\{1,\} href="ImageMagick-\([0-9.-]\{1,\}\).tar.gz">.\{1,\}$/{
    s//\1/p
    q
    }'`
    if [ -z "$new_version" ];then
        echo -e "探测php新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    version_compare $PHP_VERSION $new_version
    if [ "$?" !=0 ];then
        echo -e "PHP current version: \033[0;33m${PHP_VERSION}\033[0m\tserver's version: \033[0;35m${new_version}\033[0m"
    fi

    echo -e "PHP VERSION is \033[0;32mthe latest.\033[0m"
}
# }}}
# {{{ function check_pecl_ext_version()
function check_pecl_ext_version()
{
    local ext=$1;
    local new_version=`curl http://pecl.php.net/package/${ext} 2>/dev/null|sed -n "/^.\{1,\}${ext}-\([0-9.]\{1,\}\).tgz.\{1,\}$/{
         s//\1/p
         q
         }"`;

    if [ -z "$new_version" ];then
        echo -e "探测php扩展${ext}的新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    local version=`echo ${ext}_VERSION|tr '[a-z]' '[A-Z]'`
    version_compare ${!version} $new_version
    if [ "$?" !=0 ];then
        echo -e "PHP extension ${ext} current version: \033[0;33m${!version}\033[0m\tserver's version: \033[0;35m${new_version}\033[0m"
    fi

    echo -e "PHP extension ${ext} VERSION is \033[0;32mthe latest.\033[0m"
}
# }}}
# {{{ function check_sourceforge_soft_version()
function check_sourceforge_soft_version()
{
    local soft=$1
    local new_version=`curl https://sourceforge.net/projects/${soft}/files/${soft}2/ 2>/dev/null|sed -n "/^.\{1,\}Download \{1,\}${soft}-\([0-9.]\{1,\}\).tar\..\{1,\}$/{
         s//\1/p
         q
        }"`;
     if [ -z "$new_version" ];then
         echo -e "探测${soft}的新版本\033[0;31m失败\033[0m" >&2
         return 1;
     fi

     local version=`echo ${soft}_VERSION|tr '[a-z]' '[A-Z]'`
     version_compare ${!version} $new_version
     if [ "$?" !=0 ];then
         echo -e "${soft} current version: \033[0;33m${!version}\033[0m\tserver's version: \033[0;35m${new_version}\033[0m"
     fi

     echo -e "${soft} VERSION is \033[0;32mthe latest.\033[0m"
}
# }}}
# {{{ function version_compare()
function version_compare()
{
    return 0;
    return 1;
}
# }}}
# {{{ function pkg_config_path_init()
function pkg_config_path_init()
{
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
# {{{ function export_path()
function export_path()
{
    export PATH="$COMPILE_BASE/bin:$CONTRIB_BASE/bin:$PATH"
}
# }}}
