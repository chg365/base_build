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
# {{{ function sed_quote()
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
            if [ "$OS_NAME" = "darwin" ];then
                str="${str} -L${i}"
            elif [ "$OS_NAME" = "linux" ];then
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
    echo "**************************  ${@}  $(date "+%Y-%m-%d %H:%M:%S") ************************"
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

    if [ "${@#*/}" = "util-linux" ];then
        make && sudo make install
        sudo chown -R `whoami` $UTIL_LINUX_BASE
    else
        make && make install
    fi

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
        return $?;
    fi

    if [ -f "$FILE_NAME" ];then
        return 0;
    fi

    if [ -z "$FILE_URL" ];then
        is_finished_wget "1/$FILE_NAME"
        return $?;
    fi

    wget --content-disposition --no-check-certificate $FILE_URL -O $FILE_NAME
    local wget_flag="$?"
    if [ "$wget_flag" = "8" ];then
        wget --no-check-certificate $FILE_URL -O $FILE_NAME
        local wget_flag="$?"
    fi

    if [ ! -s "$FILE_NAME" ];then
        echo "文件[${FILE_NAME}]为空, 删除" >&2;
        rm -f $FILE_NAME
    fi

    is_finished_wget "$wget_flag/$FILE_NAME"
    return $?;
}
# }}}
# function wget_lib_sqlite() {{{
function wget_lib_sqlite()
{
    local year=`curl -Lk http://www.sqlite.org/chronology.html 2>/dev/null |
        sed -n "/^ \{0,\}<tr/{N;s/^ \{0,\}<tr.\{1,\}>\([0-9]\{4\}\)-[0-9]\{1,2\}-[0-9]\{1,2\}<.\{1,\}data-sortkey=['\"]\([0-9]\{1,\}\)['\"].\{1,\}<\/tr> \{0,\}$/\1 \2/p;}" |
        grep $SQLITE_VERSION |
        awk '{ print $1; }'`

    if [ "$year" = "" ];then
        local year=`date +%Y`
    fi

    wget_lib $SQLITE_FILE_NAME "https://sqlite.org/${year}/$SQLITE_FILE_NAME"
}
# }}}
# function wget_lib_boost() {{{
function wget_lib_boost()
{
    wget_lib $BOOST_FILE_NAME "https://sourceforge.net/projects/boost/files/boost/${BOOST_VERSION//_/.}/$BOOST_FILE_NAME/download"
}
# }}}
# function wget_lib_xunsearch() {{{
function wget_lib_xunsearch()
{
    wget_lib $XUNSEARCH_FULL_FILE_NAME "http://www.xunsearch.com/download/xunsearch-full/$XUNSEARCH_FULL_FILE_NAME"
    local flag="$?"
    if [ "$flag" != "0" ];then
        return $flag;
    fi
    if [ -f "$XUNSEARCH_FILE_NAME" -a -f "$SCWS_DICT_FILE_NAME" -a -f "$SCWS_FILE_NAME" -a -f "$XAPIAN_CORE_SCWS_FILE_NAME" -a -f "$XUNSEARCH_SDK_FILE_NAME" ]; then
        return 0;
    fi
    decompress $XUNSEARCH_FULL_FILE_NAME
    local flag="$?"
    if [ "$flag" != "0" ];then
        return $flag;
    fi

    for i in `echo $SCWS_DICT_FILE_NAME $SCWS_FILE_NAME $XAPIAN_CORE_SCWS_FILE_NAME $XUNSEARCH_FILE_NAME $XUNSEARCH_SDK_FILE_NAME`;
    do
        if [ ! -f "./xunsearch-full-${XUNSEARCH_FULL_VERSION}/packages/${i}" ];then
            echo "Warning: file not exists. file: ./xunsearch-full-${XUNSEARCH_FULL_VERSION}/packages/${i}" >&2
            continue;
        fi
        if [ -f "./${i}" ];then
            continue;
        fi
        cp xunsearch-full-${XUNSEARCH_FULL_VERSION}/packages/${i} ./
    done

    rm -rf xunsearch-full-${XUNSEARCH_FULL_VERSION}
}
# }}}
# function wget_lib_browscap() {{{
function wget_lib_browscap()
{
    #wget_lib $BROWSCAP_INI_FILE_NAME  "https://browscap.org/stream?q=PHP_BrowsCapINI"
    # wget_lib $BROWSCAP_INI_FILE_NAME  "https://browscap.org/stream?q=Full_PHP_BrowsCapINI"
    wget_lib $BROWSCAP_INI_FILE_NAME  "https://browscap.org/stream?q=Lite_PHP_BrowsCapINI"
}
# }}}
# function rm_bak_file() {{{
function rm_bak_file()
{
    for i in `find $1 -type f | grep '\.bak\.'`;
    do
        if [ -f "$i" ];then
            rm -rf "$i"
        fi
    done
}
# }}}
# {{{ function decompress()
function decompress()
{
    local FILE_NAME="$1"
    local exdir="$2"

    local tmp_str="";
    if [ "$exdir" != "" -a -d "$exdir" ];then
        tmp_str="-C $exdir"
    fi

    if [ -z "$FILE_NAME" ] || [ ! -f "$FILE_NAME" ] ;then
        return 1;
    fi

    if [ "${FILE_NAME%%.tar.xz}" != "$FILE_NAME" ];then
        tar Jxf $FILE_NAME $tmp_str
    elif [ "${FILE_NAME%%.txz}" != "$FILE_NAME" ];then
        tar Jxf $FILE_NAME $tmp_str
    elif [ "${FILE_NAME%%.tar.Z}" != "$FILE_NAME" ];then
        tar jxf $FILE_NAME $tmp_str
    elif [ "${FILE_NAME%%.tar.bz2}" != "$FILE_NAME" ];then
        tar jxf $FILE_NAME $tmp_str
    elif [ "${FILE_NAME%%.tar.gz}" != "$FILE_NAME" ];then
        tar zxf $FILE_NAME $tmp_str
    elif [ "${FILE_NAME%%.tgz}" != "$FILE_NAME" ];then
        tar zxf $FILE_NAME $tmp_str
    elif [ "${FILE_NAME%%.tar.lz}" != "$FILE_NAME" ];then
        tar --lzip -xf $FILE_NAME $tmp_str
    elif [ "${FILE_NAME%%.zip}" != "$FILE_NAME" ];then
        if [ "$exdir" != "" ];then
            tmp_str="-d $exdir"
        fi
        unzip -q $FILE_NAME $tmp_str
    elif [ "${FILE_NAME%%.dmg}" != "$FILE_NAME" ];then
        if [ "$tmp_str" != "" ];then
            tmp_str="-d $exdir"
        fi
        hdiutil attach $FILE_NAME
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
    wget_lib $ICU_FILE_NAME           "http://download.icu-project.org/files/icu4c/$ICU_VERSION/$ICU_FILE_NAME"
    #wget_lib $ICU_FILE_NAME           "https://fossies.org/linux/misc/$ICU_FILE_NAME"
    # http://cdnetworks-kr-2.dl.sourceforge.net/project/libpng/zlib/$ZLIB_VERSION/$ZLIB_FILE_NAME
    wget_lib $ZLIB_FILE_NAME          "http://zlib.net/$ZLIB_FILE_NAME"
    wget_lib $LIBZIP_FILE_NAME        "https://libzip.org/download/$LIBZIP_FILE_NAME"
    wget_lib $READLINE_FILE_NAME      "http://ftp.gnu.org/gnu/readline/$READLINE_FILE_NAME"
    wget_lib $GETTEXT_FILE_NAME       "http://ftp.gnu.org/gnu/gettext/$GETTEXT_FILE_NAME"
    wget_lib $LIBICONV_FILE_NAME      "http://ftp.gnu.org/gnu/libiconv/$LIBICONV_FILE_NAME"
    wget_lib $LIBXML2_FILE_NAME       "ftp://xmlsoft.org/libxml2/$LIBXML2_FILE_NAME"
    wget_lib $LIBWEBP_FILE_NAME       "https://github.com/webmproject/libwebp/archive/v${LIBWEBP_FILE_NAME##*-}"
    wget_lib $FRIBIDI_FILE_NAME       "https://github.com/fribidi/fribidi/archive/v${FRIBIDI_FILE_NAME##*-}"
    wget_lib $JSON_FILE_NAME          "https://s3.amazonaws.com/json-c_releases/releases/$JSON_FILE_NAME"
    # http://sourceforge.net/projects/mcrypt/files/MCrypt/2.6.8/mcrypt-2.6.8.tar.gz/download
    wget_lib $LIBMCRYPT_FILE_NAME     "http://sourceforge.net/projects/mcrypt/files/Libmcrypt/$LIBMCRYPT_VERSION/$LIBMCRYPT_FILE_NAME/download"
    wget_lib $LIBWBXML_FILE_NAME      "https://sourceforge.net/projects/libwbxml/files/libwbxml/${LIBWBXML_VERSION}/${LIBWBXML_FILE_NAME}/download"
    wget_lib $LIBUUID_FILE_NAME       "https://sourceforge.net/projects/libuuid/files/$LIBUUID_FILE_NAME/download"
    wget_lib $CURL_FILE_NAME          "http://curl.haxx.se/download/$CURL_FILE_NAME"
    # http://downloads.mysql.com/archives/mysql-${MYSQL_VERSION%.*}/$MYSQL_FILE_NAME
    # http://mysql.oss.eznetsols.org/Downloads/MySQL-${MYSQL_VERSION%.*}/$MYSQL_FILE_NAME
    wget_lib $MYSQL_FILE_NAME         "http://cdn.mysql.com/Downloads/MySQL-${MYSQL_VERSION%.*}/$MYSQL_FILE_NAME"
    wget_lib_sqlite
    wget_lib_boost
    wget_lib_xunsearch
    wget_lib $PCRE_FILE_NAME          "http://sourceforge.net/projects/pcre/files/pcre/$PCRE_VERSION/$PCRE_FILE_NAME/download"
    wget_lib $NGINX_FILE_NAME         "http://nginx.org/download/$NGINX_FILE_NAME"
    wget_lib $NODEJS_FILE_NAME        "https://nodejs.org/dist/v${NODEJS_VERSION}/${NODEJS_FILE_NAME}"
    #wget_lib $CALIBRE_FILE_NAME       "https://github.com/kovidgoyal/calibre/releases/download/v${CALIBRE_VERSION}/${CALIBRE_FILE_NAME}"
    wget_lib $CALIBRE_FILE_NAME       "https://download.calibre-ebook.com/${CALIBRE_VERSION}/${CALIBRE_FILE_NAME}"
    wget_lib $GITBOOK_FILE_NAME       "https://github.com/GitbookIO/gitbook/archive/${GITBOOK_FILE_NAME##*-}"
    wget_lib $GITBOOK_CLI_FILE_NAME   "https://github.com/GitbookIO/gitbook-cli/archive/${GITBOOK_CLI_FILE_NAME##*-}"
    wget_lib $NGHTTP2_FILE_NAME       "https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERSION}/${NGHTTP2_FILE_NAME}"
    wget_lib $PHP_FILE_NAME           "http://cn2.php.net/distributions/$PHP_FILE_NAME"
    wget_lib $PTHREADS_FILE_NAME      "https://pecl.php.net/get/$PTHREADS_FILE_NAME"
    wget_lib $ZIP_FILE_NAME           "https://pecl.php.net/get/$ZIP_FILE_NAME"
    wget_lib $SWOOLE_FILE_NAME        "https://pecl.php.net/get/$SWOOLE_FILE_NAME"
    wget_lib $PHP_PROTOBUF_FILE_NAME  "https://pecl.php.net/get/$PHP_PROTOBUF_FILE_NAME"
    wget_lib $PHP_GRPC_FILE_NAME      "https://pecl.php.net/get/$PHP_GRPC_FILE_NAME"
    wget_lib $LIBXSLT_FILE_NAME       "ftp://xmlsoft.org/libxslt/$LIBXSLT_FILE_NAME"
    wget_lib $TIDY_FILE_NAME          "https://github.com/htacg/tidy-html5/archive/${TIDY_FILE_NAME##*-}"
    wget_lib $SPHINX_FILE_NAME        "https://github.com/sphinxsearch/sphinx/archive/${SPHINX_FILE_NAME#*-}"
    wget_lib $PHP_SPHINX_FILE_NAME    "https://github.com/php/pecl-search_engine-sphinx/archive/${PHP_SPHINX_FILE_NAME##*-}"
    wget_lib $RSYSLOG_FILE_NAME       "http://www.rsyslog.com/files/download/rsyslog/${RSYSLOG_FILE_NAME}"
    wget_lib $LOGROTATE_FILE_NAME     "https://github.com/logrotate/logrotate/releases/download/$LOGROTATE_VERSION/$LOGROTATE_FILE_NAME"
    #wget_lib $LIBFASTJSON_FILE_NAME   "https://github.com/rsyslog/libfastjson/archive/v${LIBFASTJSON_FILE_NAME##*-}"
    wget_lib $LIBFASTJSON_FILE_NAME   "http://download.rsyslog.com/libfastjson/${LIBFASTJSON_FILE_NAME}"
    #wget_lib $LIBLOGGING_FILE_NAME    "https://github.com/rsyslog/liblogging/archive/v${LIBLOGGING_FILE_NAME##*-}"
    wget_lib $LIBLOGGING_FILE_NAME    "http://download.rsyslog.com/liblogging/${LIBLOGGING_FILE_NAME}"
    wget_lib $LIBGCRYPT_FILE_NAME     "ftp://ftp.gnupg.org/gcrypt/libgcrypt/${LIBGCRYPT_FILE_NAME}"
    wget_lib $LIBGPG_ERROR_FILE_NAME  "ftp://ftp.gnupg.org/gcrypt/libgpg-error//${LIBGPG_ERROR_FILE_NAME}"
    wget_lib $LIBESTR_FILE_NAME       "http://libestr.adiscon.com/files/download/${LIBESTR_FILE_NAME}"

    wget_lib $XAPIAN_CORE_FILE_NAME     "https://oligarchy.co.uk/xapian/${XAPIAN_CORE_VERSION}/${XAPIAN_CORE_FILE_NAME}"
    wget_lib $XAPIAN_OMEGA_FILE_NAME    "https://oligarchy.co.uk/xapian/${XAPIAN_OMEGA_VERSION}/${XAPIAN_OMEGA_FILE_NAME}"
    wget_lib $XAPIAN_BINDINGS_FILE_NAME "https://oligarchy.co.uk/xapian/${XAPIAN_BINDINGS_VERSION}/${XAPIAN_BINDINGS_FILE_NAME}"

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
    wget_lib $FONTFORGE_FILE_NAME     "https://github.com/fontforge/fontforge/releases/download/${FONTFORGE_VERSION}/${FONTFORGE_FILE_NAME}"
    #wget_lib $FONTFORGE_FILE_NAME     "https://github.com/fontforge/fontforge/archive/${FONTFORGE_FILE_NAME#*-}"
    wget_lib $PDF2HTMLEX_FILE_NAME    "https://github.com/coolwanglu/pdf2htmlEX/archive/v${PDF2HTMLEX_FILE_NAME#*-}"
    wget_lib $DEHYDRATED_FILE_NAME    "https://github.com/lukas2511/dehydrated/archive/v${DEHYDRATED_FILE_NAME#*-}"
    wget_lib $PANGO_FILE_NAME         "http://ftp.gnome.org/pub/GNOME/sources/pango/${PANGO_VERSION%.*}/$PANGO_FILE_NAME"
    wget_lib $LIBXPM_FILE_NAME        "https://www.x.org/releases/individual/lib/$LIBXPM_FILE_NAME"
    wget_lib $LIBXEXT_FILE_NAME       "https://www.x.org/releases/individual/lib/$LIBXEXT_FILE_NAME"
    # wget_lib $LIBGD_FILE_NAME       "https://bitbucket.org/libgd/gd-libgd/downloads/$LIBGD_FILE_NAME"
    wget_lib $LIBGD_FILE_NAME         "http://fossies.org/linux/www/$LIBGD_FILE_NAME"
    wget_lib $IMAGEMAGICK_FILE_NAME  "http://www.imagemagick.org/download/releases/${IMAGEMAGICK_FILE_NAME}"
    if [ "$?" = "1" ]; then
    wget_lib $IMAGEMAGICK_FILE_NAME  "https://github.com/ImageMagick/ImageMagick/archive/${IMAGEMAGICK_FILE_NAME#*-}"
    fi
    wget_lib $GMP_FILE_NAME           "ftp://ftp.gmplib.org/pub/gmp/$GMP_FILE_NAME"
    #wget_lib $IMAP_FILE_NAME          "ftp://ftp.cac.washington.edu/imap/$IMAP_FILE_NAME"
    wget_lib $IMAP_FILE_NAME          "https://www.mirrorservice.org/sites/ftp.cac.washington.edu/imap/$IMAP_FILE_NAME"
    local version=${KERBEROS_VERSION%.*};
    if [ "${version%.*}" = "${version}" ] ;then
        local version=${KERBEROS_VERSION}
    fi
    wget_lib $KERBEROS_FILE_NAME      "http://web.mit.edu/kerberos/dist/krb5/${version}/$KERBEROS_FILE_NAME"
    wget_lib $LIBMEMCACHED_FILE_NAME  "https://launchpad.net/libmemcached/${LIBMEMCACHED_VERSION%.*}/$LIBMEMCACHED_VERSION/+download/$LIBMEMCACHED_FILE_NAME"
    #wget_lib $MEMCACHED_FILE_NAME     "https://github.com/memcached/memcached/archive/${MEMCACHED_FILE_NAME##*-}"
    wget_lib $MEMCACHED_FILE_NAME     "http://memcached.org/files/${MEMCACHED_FILE_NAME}"
    wget_lib $REDIS_FILE_NAME         "http://download.redis.io/releases/${REDIS_FILE_NAME}"
    # wget_lib $LIBEVENT_FILE_NAME      "https://sourceforge.net/projects/levent/files//libevent-${LIBEVENT_VERSION%.*}/$LIBEVENT_FILE_NAME"
    # wget_lib $LIBEVENT_FILE_NAME      "https://sourceforge.net/projects/levent/files/release-${LIBEVENT_VERSION}-stable/$LIBEVENT_FILE_NAME/download"
    wget_lib $LIBEVENT_FILE_NAME      "https://github.com/libevent/libevent/archive/${LIBEVENT_FILE_NAME#*-}"
    wget_lib $GEARMAND_FILE_NAME       "https://github.com/gearman/gearmand/releases/download/${GEARMAND_VERSION}/${GEARMAND_FILE_NAME}"
    #wget_lib $GEARMAND_FILE_NAME      "https://github.com/gearman/gearmand/archive/${GEARMAND_FILE_NAME#*-}"
    wget_lib $PHP_GEARMAN_FILE_NAME   "https://github.com/wcgallego/pecl-gearman/archive/gearman-${PHP_GEARMAN_VERSION}.tar.gz"
    wget_lib $QRENCODE_FILE_NAME   "http://fukuchi.org/works/qrencode/$QRENCODE_FILE_NAME"
    wget_lib $POSTGRESQL_FILE_NAME    "https://ftp.postgresql.org/pub/source/v$POSTGRESQL_VERSION/$POSTGRESQL_FILE_NAME"
    wget_lib $PGBOUNCER_FILE_NAME     "https://pgbouncer.github.io/downloads/files/${PGBOUNCER_VERSION}/$PGBOUNCER_FILE_NAME"
    wget_lib $APR_FILE_NAME           "http://mirror.bit.edu.cn/apache/apr/$APR_FILE_NAME"
    wget_lib $APR_UTIL_FILE_NAME      "http://mirror.bit.edu.cn/apache/apr/$APR_UTIL_FILE_NAME"
    # http://mirror.bjtu.edu.cn/apache/httpd/$APACHE_FILE_NAME
    wget_lib $APACHE_FILE_NAME        "http://archive.apache.org/dist/httpd/$APACHE_FILE_NAME"
    wget_lib $APCU_FILE_NAME          "https://pecl.php.net/get/$APCU_FILE_NAME"
    wget_lib $APCU_BC_FILE_NAME       "https://pecl.php.net/get/$APCU_BC_FILE_NAME"
    wget_lib $YAF_FILE_NAME           "https://pecl.php.net/get/$YAF_FILE_NAME"
    wget_lib $PHALCON_FILE_NAME       "https://github.com/phalcon/cphalcon/archive/v${PHALCON_FILE_NAME#*-}"
    wget_lib $XDEBUG_FILE_NAME        "https://pecl.php.net/get/$XDEBUG_FILE_NAME"
    wget_lib $RAPHF_FILE_NAME         "https://pecl.php.net/get/$RAPHF_FILE_NAME"
    wget_lib $PROPRO_FILE_NAME        "https://pecl.php.net/get/$PROPRO_FILE_NAME"
    wget_lib $PECL_HTTP_FILE_NAME     "https://pecl.php.net/get/$PECL_HTTP_FILE_NAME"
    wget_lib $AMQP_FILE_NAME          "https://pecl.php.net/get/$AMQP_FILE_NAME"
    wget_lib $MAILPARSE_FILE_NAME     "https://pecl.php.net/get/$MAILPARSE_FILE_NAME"
    wget_lib $PHP_REDIS_FILE_NAME     "https://pecl.php.net/get/$PHP_REDIS_FILE_NAME"
    wget_lib $PHP_MONGODB_FILE_NAME   "https://pecl.php.net/get/$PHP_MONGODB_FILE_NAME"
    wget_lib $SOLR_FILE_NAME          "https://pecl.php.net/get/$SOLR_FILE_NAME"

    wget_lib $PHP_MEMCACHED_FILE_NAME "https://pecl.php.net/get/$PHP_MEMCACHED_FILE_NAME"
    wget_lib $EVENT_FILE_NAME         "https://pecl.php.net/get/$EVENT_FILE_NAME"
    wget_lib $DIO_FILE_NAME           "https://pecl.php.net/get/$DIO_FILE_NAME"
    wget_lib $PHP_LIBEVENT_FILE_NAME  "https://pecl.php.net/get/$PHP_LIBEVENT_FILE_NAME"
    wget_lib $IMAGICK_FILE_NAME       "https://pecl.php.net/get/$IMAGICK_FILE_NAME"
    #if [ `echo "${PHP_VERSION}" "7.1.99"|tr " " "\n"|sort -rV|head -1` = "7.1.99" ]; then
        wget_lib $PHP_LIBSODIUM_FILE_NAME "https://pecl.php.net/get/$PHP_LIBSODIUM_FILE_NAME"
    #fi
    wget_lib $PHP_QRENCODE_FILE_NAME  "https://github.com/chg365/qrencode/archive/${PHP_QRENCODE_FILE_NAME#*-}"
    wget_lib $COMPOSER_FILE_NAME      "https://github.com/composer/composer/archive/${COMPOSER_FILE_NAME#*-}"
    wget_lib_browscap
    wget_lib $PATCHELF_FILE_NAME      "https://github.com/NixOS/patchelf/archive/${PATCHELF_FILE_NAME##*-}"
    wget_lib $TESSERACT_FILE_NAME     "https://github.com/tesseract-ocr/tesseract/archive/${TESSERACT_FILE_NAME##*-}"

    wget_lib $LARAVEL_FILE_NAME       "https://github.com/laravel/laravel/archive/v${LARAVEL_FILE_NAME#*-}"
    wget_lib $HIREDIS_FILE_NAME       "https://github.com/redis/hiredis/archive/v${HIREDIS_FILE_NAME#*-}"
    wget_lib $LARAVEL_FRAMEWORK_FILE_NAME "https://github.com/laravel/framework/archive/v${LARAVEL_FRAMEWORK_FILE_NAME#*-}"
    wget_lib $ZEND_FILE_NAME          "https://packages.zendframework.com/releases/ZendFramework-$ZEND_VERSION/$ZEND_FILE_NAME"
    wget_lib $SMARTY_FILE_NAME        "https://github.com/smarty-php/smarty/archive/v${SMARTY_FILE_NAME#*-}"
    wget_lib $HTMLPURIFIER_FILE_NAME  "https://github.com/ezyang/htmlpurifier/archive/v${HTMLPURIFIER_FILE_NAME#*-}"
    wget_lib $CKEDITOR_FILE_NAME      "http://download.cksource.com/CKEditor/CKEditor/CKEditor%20$CKEDITOR_VERSION/$CKEDITOR_FILE_NAME"
    wget_lib $JQUERY_FILE_NAME        "http://code.jquery.com/$JQUERY_FILE_NAME"
    wget_lib $JQUERY3_FILE_NAME       "http://code.jquery.com/$JQUERY3_FILE_NAME"
    wget_lib $D3_FILE_NAME            "https://github.com/d3/d3/releases/download/v${D3_VERSION}/d3.${D3_FILE_NAME#*${D3_VERSION}.}"
    wget_lib $CHARTJS_FILE_NAME       "https://github.com/chartjs/Chart.js/archive/v${CHARTJS_FILE_NAME#*-}"
    wget_lib $RABBITMQ_C_FILE_NAME    "https://github.com/alanxz/rabbitmq-c/archive/v${RABBITMQ_C_FILE_NAME##*-}"

    wget_lib $ZEROMQ_FILE_NAME        "https://github.com/zeromq/libzmq/releases/download/v${ZEROMQ_VERSION}/$ZEROMQ_FILE_NAME"
    #wget_lib $LIBUNWIND_FILE_NAME     "http://download.savannah.gnu.org/releases/libunwind/$LIBUNWIND_FILE_NAME"
    wget_lib $LIBUNWIND_FILE_NAME     "https://github.com/libunwind/libunwind/releases/download/v${LIBUNWIND_VERSION}/$LIBUNWIND_FILE_NAME"
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

    #wget_lib $PHANTOMJS_FILE_NAME     "https://github.com/ariya/phantomjs/archive/${PHANTOMJS_FILE_NAME#*-}"
    wget_lib $PHANTOMJS_FILE_NAME     "https://bitbucket.org/ariya/phantomjs/downloads/${PHANTOMJS_FILE_NAME}"

    wget_lib $FAMOUS_FILE_NAME "https://github.com/Famous/famous/archive/${FAMOUS_FILE_NAME##*-}"
    wget_lib $FAMOUS_FRAMEWORK_FILE_NAME "https://github.com/Famous/framework/archive/v${FAMOUS_FRAMEWORK_FILE_NAME##*-}"
    wget_lib $FAMOUS_ANGULAR_FILE_NAME "https://github.com/Famous/famous-angular/archive/${FAMOUS_ANGULAR_FILE_NAME##*-}"

    wget_lib $NGINX_UPLOAD_PROGRESS_MODULE_FILE_NAME "https://github.com/masterzen/nginx-upload-progress-module/archive/v${NGINX_UPLOAD_PROGRESS_MODULE_FILE_NAME##*-}"
    wget_lib $NGINX_PUSH_STREAM_MODULE_FILE_NAME "https://github.com/wandenberg/nginx-push-stream-module/archive/${NGINX_PUSH_STREAM_MODULE_FILE_NAME##*-}"
    wget_lib $NGINX_UPLOAD_MODULE_FILE_NAME "https://github.com/vkholodkov/nginx-upload-module/archive/${NGINX_UPLOAD_MODULE_FILE_NAME##*-}"
    wget_lib $NGINX_STICKY_MODULE_FILE_NAME "https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng/get/${NGINX_STICKY_MODULE_FILE_NAME##*-}"
    wget_lib $NGINX_HTTP_GEOIP2_MODULE_FILE_NAME "https://github.com/leev/ngx_http_geoip2_module/archive/${NGINX_HTTP_GEOIP2_MODULE_FILE_NAME##*-}"

    wget_lib $PYTHON_FILE_NAME "https://www.python.org/ftp/python/${PYTHON_VERSION}/${PYTHON_FILE_NAME}"

#    if [ "$OS_NAME" = 'darwin' ];then

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
    if grep -q "^ \{0,1\}extension=$(sed_quote $1)" $php_ini ;then
        return;
    fi
    local line=`sed -n '/^;\{0,1\}extension=/h;${x;p;}' $php_ini`;
    sed -i.bak.$$ "/^$line\$/{a\\
extension=$1
;}" $php_ini

    #sed -i "/^;\{0,1\}extension=/h;\${x;a\\
    #    extension=$1
    #    ;x;}" $php_ini
    rm_bak_file ${php_ini}.bak.*
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
    rm_bak_file ${php_ini}.bak.*
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
    rm_bak_file ${php_ini}.bak.*
}
# }}}
# function init_php_ini() {{{
function init_php_ini()
{
    # log_errors
    local pattern='^log_errors \{0,\}= \{0,\}\([oO][nN]\) \{0,\}$';
    change_php_ini "$pattern" "log_errors = Off"
    # error_reporting
    local pattern='^error_reporting \{0,\}= \{0,\}\(.\{1,\}\)$';
    change_php_ini "$pattern" "error_reporting = E_ALL"
    # error_log
    local pattern='^;error_log \{0,\}= \{0,\}syslog \{0,\}$';
    change_php_ini "$pattern" "error_log = \\\"$(sed_quote2 "$LOG_DIR/php/error.log" )\\\""
    # ignore_repeated_errors
    local pattern='^ignore_repeated_errors \{0,\}= \{0,\}\([oO][fF]\{2\}\)$';
    change_php_ini "$pattern" "ignore_repeated_errors = On"
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
    # ;openssl.cafile
    local pattern='^; \{0,\}openssl.cafile \{0,\}=.\{0,\}$';
    change_php_ini "$pattern" "openssl.cafile = \\\"$(sed_quote2 "$SSL_CONFIG_DIR/certs/ca-bundle.crt" )\\\""
    # ;openssl.capath

    # ;opcache.enable_cli=0
    local pattern='^; \{0,\}opcache.enable_cli \{0,\}=.\{0,\}$';
    change_php_ini "$pattern" "opcache.enable_cli = 0"

    # session.cookie_httponly =
    local pattern='^session.cookie_httponly \{0,\}= \{0,\}.\{0,\}$';
    change_php_ini "$pattern" "session.cookie_httponly = 1"

    # soap.wsdl_cache_dir="/tmp"
    mkdir -p $WSDL_CACHE_DIR
    local pattern='^soap\.wsdl_cache_dir \{0,\}= \{0,\}\"\/tmp\"$';
    change_php_ini "$pattern" "soap.wsdl_cache_dir= \\\"$( echo $WSDL_CACHE_DIR|sed 's/\//\\\//g' )\\\""

    # session.use_strict_mode = 0
    local pattern='^session\.use_strict_mode \{0,\}=.\{0,\}$';
    change_php_ini "$pattern" "session.use_strict_mode = 1"
}
# }}}
# function change_php_fpm_ini() {{{
function change_php_fpm_ini()
{
    local fpm_ini=$3;
    local num=`sed -n "/$1/=" $fpm_ini`;
    if [ "$num" = "" ];then
        echo "从${fpm_ini}文件中查找pattern($1)失败";
        exit 1;
    fi

    sed -i.bak.$$ "${num[0]}s/$1/${2//\//\\/}/" $fpm_ini
    if [ $? != "0" ];then
        echo "在${fpm_ini}文件中执行替换失败. pattern($1) ($2)";
        exit 1;
    fi
    rm_bak_file ${fpm_ini}.bak.*
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

    # user
    local pattern='^user \{0,\}= \{0,\}.\{1,\}$';
    change_php_fpm_ini "$pattern" "user = $PHP_FPM_USER" "$PHP_FPM_CONFIG_DIR/php-fpm.d/www.conf"

    # group
    local pattern='^group \{0,\}= \{0,\}.\{1,\}$';
    change_php_fpm_ini "$pattern" "group = $PHP_FPM_GROUP" "$PHP_FPM_CONFIG_DIR/php-fpm.d/www.conf"

    # listen
    local pattern='^\(listen = [0-9.]\{1,\}:\)[0-9]\{1,\}$';
    change_php_fpm_ini "$pattern" "\19040" "$PHP_FPM_CONFIG_DIR/php-fpm.d/www.conf"

    # pm.max_children 30
    local pattern='^\(pm.max_children = \)[0-9.]\{1,\}$';
    change_php_fpm_ini "$pattern" "\130" "$PHP_FPM_CONFIG_DIR/php-fpm.d/www.conf"

    # pm.start_servers 10
    local pattern='^\(pm.start_servers = \)[0-9.]\{1,\}$';
    change_php_fpm_ini "$pattern" "\110" "$PHP_FPM_CONFIG_DIR/php-fpm.d/www.conf"

    # pm.min_spare_servers 5
    local pattern='^\(pm.min_spare_servers = \)[0-9.]\{1,\}$';
    change_php_fpm_ini "$pattern" "\15" "$PHP_FPM_CONFIG_DIR/php-fpm.d/www.conf"

    # pm.max_spare_servers 15
    local pattern='^\(pm.max_spare_servers = \)[0-9.]\{1,\}$';
    change_php_fpm_ini "$pattern" "\115" "$PHP_FPM_CONFIG_DIR/php-fpm.d/www.conf"

    # pm.max_requests 1024
    local pattern='^;\{0,\}\(pm.max_requests = \)[0-9.]\{1,\}$';
    change_php_fpm_ini "$pattern" "\11024" "$PHP_FPM_CONFIG_DIR/php-fpm.d/www.conf"

    # catch_workers_output = yes
    local pattern='^;\(catch_workers_output = yes\)$';
    change_php_fpm_ini "$pattern" "\1" "$PHP_FPM_CONFIG_DIR/php-fpm.d/www.conf"
}
# }}}
# function init_mysql_cnf() {{{
function init_mysql_cnf()
{
    sed -i.bak.$$ "s/\<MYSQL_BASE_DIR\>/$( echo $MYSQL_BASE|sed 's/\//\\\//g' )/" $mysql_cnf;
    sed -i.bak.$$ "s/\<MYSQL_RUN_DIR\>/$( echo $MYSQL_RUN_DIR|sed 's/\//\\\//g' )/" $mysql_cnf;
    sed -i.bak.$$ "s/\<MYSQL_CONFIG_DIR\>/$( echo $MYSQL_CONFIG_DIR|sed 's/\//\\\//g' )/" $mysql_cnf;
    sed -i.bak.$$ "s/\<MYSQL_DATA_DIR\>/$( echo $MYSQL_DATA_DIR|sed 's/\//\\\//g' )/" $mysql_cnf;
    sed -i.bak.$$ "s/\<LOG_DIR\>/$( echo ${LOG_DIR}/mysql|sed 's/\//\\\//g' )/" $mysql_cnf;

    rm_bak_file ${mysql_cnf}.bak.*
}
# }}}
# function init_nginx_conf() {{{
function init_nginx_conf()
{
    mkdir -p $NGINX_CONFIG_DIR/
    local NGINX_CONF_FILE="$NGINX_CONFIG_DIR/conf/nginx.conf"
    cp -r $curr_dir/conf/nginx/* $NGINX_CONFIG_DIR/

    for i in `find $NGINX_CONFIG_DIR/ -type f|grep -v '\.bak\.'`;
    do
        sed -i.bak.$$ "s/WEB_ROOT_DIR/$(sed_quote2 $BASE_DIR/web)/g" $i
        sed -i.bak.$$ "s/GEOIP2_DATA_DIR/$(sed_quote2 $GEOIP2_DATA_DIR)/g" $i
        sed -i.bak.$$ "s/LOG_DIR/$(sed_quote2 $LOG_DIR)/g" $i
        sed -i.bak.$$ "s/RUN_DIR/$(sed_quote2 $NGINX_RUN_DIR)/g" $i
        #sed -i.bak.$$ "s/PROJECT_NAME/$(sed_quote2 $project_abbreviation)/g" $i
        sed -i.bak.$$ "s/BODY_TEMP_PATH/$(sed_quote2 $TMP_DATA_DIR/nginx/client_body_temp )/g" $i
        sed -i.bak.$$ "s/PROXY_TEMP_PATH/$(sed_quote2 $TMP_DATA_DIR/nginx/proxy_temp )/g" $i
        sed -i.bak.$$ "s/FASTCGI_TEMP_PATH/$(sed_quote2 $TMP_DATA_DIR/nginx/fastcgi_temp )/g" $i
        sed -i.bak.$$ "s/UWSGI_TEMP_PATH/$(sed_quote2 $TMP_DATA_DIR/nginx/uwsgi_temp )/g" $i
        sed -i.bak.$$ "s/SCGI_TEMP_PATH/$(sed_quote2 $TMP_DATA_DIR/nginx/scgi_temp )/g" $i
        sed -i.bak.$$ "s/NGINX_CONF_DIR/$(sed_quote2 $NGINX_CONFIG_DIR )/g" $i
        sed -i.bak.$$ "s/TMP_DATA_DIR/$(sed_quote2 $TMP_DATA_DIR )/g" $i
        sed -i.bak.$$ "s/DEHYDRATED_CONFIG_DIR/$(sed_quote2 $DEHYDRATED_CONFIG_DIR )/g" $i
        sed -i.bak.$$ "s/SSL_CONFIG_DIR/$(sed_quote2 $SSL_CONFIG_DIR )/g" $i

        rm_bak_file ${i}.bak.*
    done
    #if is_new_version $NGINX_VERSION "1.13.0" ; then
        #sed -i.bak.$$ "s/\(^.\{1,\}ssl_protocols.\{1,\}\) \{0,\}; \{0,\}$/\1  TLSv1.3;/g" $NGINX_CONF_FILE
    #fi

    # nginx user
    sed -i.bak.$$ "s/^ \{0,\}\(user \{1,\}\)[^ ]\{1,\} \{1,\}[^ ]\{1,\} \{0,\};$/user  $NGINX_USER  ${NGINX_GROUP};/" $NGINX_CONFIG_DIR/conf/nginx.conf
    rm_bak_file ${NGINX_CONF_FILE}.bak.*

    # fastcgi_param  SERVER_SOFTWARE
    # sed -i.bak.$$ "s/^\(fastcgi_param \{1,\}SERVER_SOFTWARE \{1,\}\)nginx\/\$nginx_version;$/\1${project_name%% *}\/1.0;/" $NGINX_CONFIG_DIR/conf/fastcgi.conf;
}
# }}}
# function init_dehydrated_conf() {{{
function init_dehydrated_conf()
{
    sed -i.bak.$$ "s/^ \{0,\}#\{0,\} \{0,\}\(BASEDIR=\).\{0,\}$/\1\"$(sed_quote2 $DEHYDRATED_CONFIG_DIR )\"/g" $DEHYDRATED_CONFIG_DIR/config
    sed -i.bak.$$ "s/^ \{0,\}#\{0,\} \{0,\}\(WELLKNOWN=\).\{0,\}$/\1\"$(sed_quote2 $TMP_DATA_DIR/dehydrated )\"/g" $DEHYDRATED_CONFIG_DIR/config
    sed -i.bak.$$ "s/^ \{0,\}#\{0,\} \{0,\}\(OPENSSL_CNF=\).\{0,\}$/\1\"$(sed_quote2 $SSL_CONFIG_DIR/openssl.cnf )\"/g" $DEHYDRATED_CONFIG_DIR/config
    sed -i.bak.$$ "s/^ \{0,\}#\{0,\} \{0,\}\(LOCKFILE=\).\{0,\}$/\1\"$(sed_quote2 $BASE_DIR/run/dehydrated.lock )\"/g" $DEHYDRATED_CONFIG_DIR/config

    rm_bak_file $DEHYDRATED_CONFIG_DIR/config.bak.*

    mkdir -p $SBIN_DIR/
    cp $curr_dir/renew_cert.sh $SBIN_DIR/

    sed -i.bak.$$ "s/@project_abbreviation@/$(sed_quote2 $project_abbreviation )/g" $SBIN_DIR/renew_cert.sh
    sed -i.bak.$$ "s/@DEHYDRATED_BASE@/$(sed_quote2 $DEHYDRATED_BASE)/g" $SBIN_DIR/renew_cert.sh
    sed -i.bak.$$ "s/@DEHYDRATED_CONFIG_DIR@/$(sed_quote2 $DEHYDRATED_CONFIG_DIR)/g" $SBIN_DIR/renew_cert.sh
    sed -i.bak.$$ "s/@NGINX_BASE@/$(sed_quote2 $NGINX_BASE)/g" $SBIN_DIR/renew_cert.sh

    rm_bak_file $SBIN_DIR/renew_cert.sh.bak.*

    cp -r $curr_dir/conf/dehydrated/certs $DEHYDRATED_CONFIG_DIR/
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
    rm_bak_file ${redis_conf}.bak.*
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
# function init_rsyslog_conf() {{{
function init_rsyslog_conf()
{
    :
}
# }}}
# function init_logrotate_conf() {{{
function init_logrotate_conf()
{
    mkdir -p $LOGROTATE_CONFIG_DIR
    cp ${curr_dir}/conf/base_logrotate.conf $LOGROTATE_CONFIG_DIR/logrotate.conf
    :
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
    local FILENAME="$JPEG_BASE/bin/djpeg"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`$FILENAME -verbose < /dev/null 2>&1|sed -n '1p' |awk '{ print $(NF-1); }'`
    # local version=`$FILENAME -version 2>&1|awk '{ print $3;}'| head -1`
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
# {{{ function is_installed_readline()
function is_installed_readline()
{
    local FILENAME="$READLINE_BASE/lib/libreadline$([ "$OS_NAME" != "darwin" ] && echo ".so").${READLINE_VERSION}$([ "$OS_NAME" = "darwin" ] && echo ".dylib")"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_phantomjs()
function is_installed_phantomjs()
{
    local FILENAME="$PHANTOMJS_BASE/bin/phantomjs"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`$FILENAME -v`
    if [ "$version" != "$PHANTOMJS_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_nodejs()
function is_installed_nodejs()
{
    local FILENAME="$NODEJS_BASE/bin/node"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`$FILENAME -v`
    if [ "$version" != "v${NODEJS_VERSION}" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_calibre()
function is_installed_calibre()
{
    local FILENAME="$CALIBRE_BASE/calibre"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`$FILENAME --version|awk '{print $3;}'|tr -d ')'`
    if [ "$version" != "${CALIBRE_VERSION%.0}" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_gitbook()
function is_installed_gitbook()
{
    is_installed nodejs $NODEJS_BASE || return 1;

    #local FILENAME="$GITBOOK_BASE/book.js"
    #if [ ! -f "$FILENAME" ];then
    #    return 1;
    #fi

    PATH="$NODEJS_BASE/bin:$PATH"
    local version=`npm list gitbook -g -depth 1| sed -n '/@/p'|awk -F@ '{print $2}'|tr -d ' '`
    if [ "${version}" != "${GITBOOK_VERSION}" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_gitbook_cli()
function is_installed_gitbook_cli()
{
    is_installed nodejs $NODEJS_BASE || return 1;

    #local FILENAME="$GITBOOK_CLI_BASE/bin/book.js"
    #if [ ! -f "$FILENAME" ];then
    #    return 1;
    #fi

    local version=`npm list gitbook-cli -g -depth 1 2>/dev/null|sed -n '/@/p'|awk -F@ '{print $2;}'|tr -d ' '`
    if [ "$version" != "${GITBOOK_CLI_VERSION}" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_gitbook_pdf()
function is_installed_gitbook_pdf()
{
    is_installed nodejs $NODEJS_BASE || return 1;

    local version=`npm list gitbook-pdf -g -depth 1 2>/dev/null| sed -n '/@/p'|awk -F@ '{print $2;}'|tr -d ' '`
    if [ "$version" != "" ];then
        return;
    fi
    return 1;

    if [ "$version" != "${GITBOOK_PDF_VERSION}" ];then
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
    if [ ! -f "$SPHINX_CLIENT_BASE/lib/libsphinxclient.so" ];then
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
# {{{ function is_installed_libwbxml()
function is_installed_libwbxml()
{
    local FILENAME="$LIBWBXML_BASE/lib/pkgconfig/libwbxml2.pc"
    if [ ! -f "${FILENAME}" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$LIBWBXML_VERSION" ];then
        echo "bbb"
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_gettext()
function is_installed_gettext()
{
    if [ ! -f "$GETTEXT_BASE/bin/gettext" ];then
        return 1;
    fi
    local version=`$GETTEXT_BASE/bin/gettext --version|sed -n '1s/^.\{1,\} \{1,\}\([0-9.]\{1,\}\)$/\1/p'`
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
# {{{ function is_installed_libwebp()
function is_installed_libwebp()
{
    local FILENAME="$LIBWEBP_BASE/bin/cwebp"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`$FILENAME -version`
    if [ "$version" != "$LIBWEBP_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_fribidi()
function is_installed_fribidi()
{
    local FILENAME="$FRIBIDI_BASE/lib/pkgconfig/fribidi.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$FRIBIDI_VERSION" ];then
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
# {{{ function is_installed_patchelf()
function is_installed_patchelf()
{
    local FILENAME=$PATCHELF_BASE/bin/patchelf;
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`$FILENAME --version|awk '{print $NF;}'`
    if [ "$version" != "$PATCHELF_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_tesseract()
function is_installed_tesseract()
{
    local FILENAME=$TESSERACT_BASE/bin/tesseract;
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`$FILENAME --version|awk '{print $NF;}'`
    if [ "$version" != "$TESSERACT_VERSION" ];then
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
# {{{ function is_installed_xapian_core()
function is_installed_xapian_core()
{
    local FILENAME="$XAPIAN_CORE_BASE/lib/pkgconfig/xapian-core.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$XAPIAN_CORE_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_xapian_omega()
function is_installed_xapian_omega()
{

    local FILENAME="$XAPIAN_OMEGA_BASE/bin/omindex"

    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`$FILENAME --version|awk '{ print $NF;}'|head -1`
    if [ "${version}" != "$XAPIAN_OMEGA_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_scws()
function is_installed_scws()
{
    local FILENAME="$SCWS_BASE/bin/scws"

    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`$FILENAME -v|awk -F '[ /:]' '{print $3;}'|head -1`
    if [ "${version}" != "$SCWS_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_xapian_core_scws()
function is_installed_xapian_core_scws()
{
    local FILENAME="$XAPIAN_CORE_SCWS_BASE/lib/pkgconfig/xapian-core.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$XAPIAN_CORE_SCWS_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_xunsearch()
function is_installed_xunsearch()
{
    local FILENAME="$XUNSEARCH_BASE/bin/xs-searchd"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`$FILENAME -v |awk -F'[/ ]' '{print  $3;}'|head -1`
    if [ "${version}" != "$XUNSEARCH_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_nghttp2()
function is_installed_nghttp2()
{
    local FILENAME="$NGHTTP2_BASE/lib/pkgconfig/libnghttp2.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$NGHTTP2_VERSION" ];then
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
# {{{ function is_installed_libXext()
function is_installed_libXext()
{
    local FILENAME="$LIBXEXT_BASE/lib/pkgconfig/xext.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "${version}" != "$LIBXEXT_VERSION" ];then
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
# {{{ function is_installed_pgbouncer()
function is_installed_pgbouncer()
{
    local FILENAME="$PGBOUNCER_BASE/bin/pgbouncer"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`$FILENAME --version|awk '{ print $NF;}'|head -1`
    if [ "${version}" != "$PGBOUNCER_VERSION" ];then
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
    local version=`$NGINX_BASE/sbin/nginx -v 2>&1|awk -F'[ /]' '{ print $4; }'`
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
# {{{ function is_installed_logrotate()
function is_installed_logrotate()
{
    local FILENAME="$LOGROTATE_BASE/sbin/logrotate"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`$FILENAME --version 2>&1|awk '{print $NF;}'|head -1`
    if [ "$version" != "$LOGROTATE_VERSION" ];then
        return 1;
    fi
    return;
}
# }}}
# {{{ function is_installed_libuuid()
function is_installed_libuuid()
{
    local FILENAME="$LIBUUID_BASE/lib/pkgconfig/uuid.pc"
    if [ ! -f "$FILENAME" ];then
        return 1;
    fi
    local version=`pkg-config --modversion $FILENAME`
    if [ "$version" != "$LIBUUID_VERSION" ];then
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
    #local version=`sed -n 's/^#define MAGICKCORE_VERSION "\([0-9.-]\{1,\}\)"$/\1/p' ${IMAGEMAGICK_BASE}/include/ImageMagick-${IMAGEMAGICK_VERSION%%.*}/MagickCore/magick-baseconfig.h`;
    local version=`$IMAGEMAGICK_BASE/bin/magick -version|head -1|awk '{print $3;}'`;

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
# {{{ function is_installed_python()
function is_installed_python()
{
    local FILE_NAME="$PYTHON_BASE/bin/python${PYTHON_VERSION%%.*}"
    if [ ! -f "$FILE_NAME" ];then
        return 1;
    fi
    local version=`$FILE_NAME -V | sed -n '1p' | awk '{print $2;}'`
    if [ "$version" != "$PYTHON_VERSION" ];then
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

    local ext_name="$1"
    local ext_ver="$2"

    if [ -z "$ext_name" -o -z "$ext_ver" ];then
        echo "is_installed_php_extension 参数错误. name: $ext_name  ext_ver: $ext_ver" >&2
        return 1;
    fi

    $PHP_BASE/bin/php -m | grep -q "^${ext_name}\$"
    if [ "$?" != "0" ];then
        return 1;
    fi

    if [ "$ext_ver" = "1" -o "$ext_ver" = "php7" ]; then
        return ;
    fi

    local version=`$PHP_BASE/bin/php --ri ${ext_name}|grep -i '^version =>'|awk '{print $NF;}'`;
    if [ "$version" = "" ]; then
        return;
    fi
    # if [ "$version" != "$ext_ver" ];then
    if ! is_new_version $version "$ext_ver" ; then
        # echo "$ext_name  $version $ext_ver"
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
    if [ ! -f "$QRENCODE_BASE/bin/qrencode" ];then
        return 1;
    fi
    local version=`$QRENCODE_BASE/bin/qrencode --version 2>&1|sed -n '1p'| awk  '{ print $NF;}'`
    if [ "$version" != "$QRENCODE_VERSION" ];then
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
    if [ "$version" != "$UTIL_LINUX_VERSION" -a "${version%.0}" != "$UTIL_LINUX_VERSION" ];then
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
# {{{ function compile_xapian_core()
function compile_xapian_core()
{
    is_installed xapian_core "$XAPIAN_CORE_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    # --sysconfdir=
    XAPIAN_CORE_CONFIGURE="
        ./configure --prefix=$XAPIAN_CORE_BASE \
                    --enable-64bit-docid \
                    --enable-64bit-termcount
    "

    compile "xapian_core" "$XAPIAN_CORE_FILE_NAME" "xapian-core-$XAPIAN_CORE_VERSION/" "$XAPIAN_CORE_BASE" "XAPIAN_CORE_CONFIGURE"
}
# }}}
# {{{ function compile_xapian_omega()
function compile_xapian_omega()
{
    #compile_pkgconfig
    compile_libiconv
    compile_pcre
    compile_xapian_core

    # yum install file-devel
    is_installed xapian_omega "$XAPIAN_OMEGA_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    XAPIAN_OMEGA_CONFIGURE="
        configure_xapian_omega_command
    "

    compile "xapian_omega" "$XAPIAN_OMEGA_FILE_NAME" "xapian-omega-$XAPIAN_OMEGA_VERSION/" "$XAPIAN_OMEGA_BASE" "XAPIAN_OMEGA_CONFIGURE"
}
# }}}
# {{{ function compile_xapian_bindings_php()
function compile_xapian_bindings_php()
{
    compile_xapian_core
    compile_php

    is_installed_php_extension xapian $XAPIAN_BINDINGS_VERSION
    if [ "$?" = "0" ];then
        return;
    fi

    XAPIAN_BINDINGS_PHP_CONFIGURE="
        configure_xapian_bindings_php_command
    "

    compile "xapian_bindings_php" "$XAPIAN_BINDINGS_FILE_NAME" "xapian-bindings-$XAPIAN_BINDINGS_VERSION/" "$XAPIAN_BINDINGS_BASE" "XAPIAN_BINDINGS_PHP_CONFIGURE" "after_xapian_bindings_php_make_install"
}
# }}}
# {{{ function compile_scws()
function compile_scws()
{

    is_installed scws $SCWS_BASE
    if [ "$?" = "0" ];then
        return;
    fi

    SCWS_CONFIGURE="
        ./configure --prefix=$SCWS_BASE \
                    --sysconfdir=$SCWS_CONFIG_DIR
    "

    compile "scws" "$SCWS_FILE_NAME" "scws-$SCWS_VERSION/" "$SCWS_BASE" "SCWS_CONFIGURE"

    #拷贝字典文件
    decompress $SCWS_DICT_FILE_NAME $SCWS_CONFIG_DIR/

    if [ "$?" != "0" ];then
        echo "Waring: copy dict.utf8.xdb faild." >&2
    fi
}
# }}}
# {{{ function compile_xapian_core_scws()
function compile_xapian_core_scws()
{
    compile_scws

    is_installed xapian_core_scws "$XAPIAN_CORE_SCWS_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    XAPIAN_CORE_SCWS_CONFIGURE="
        configure_xapian_core_scws_command
    "

    compile "xapian_core_scws" "$XAPIAN_CORE_SCWS_FILE_NAME" "xapian-core-scws-$XAPIAN_CORE_SCWS_VERSION/" "$XAPIAN_CORE_SCWS_BASE" "XAPIAN_CORE_SCWS_CONFIGURE"
}
# }}}
# {{{ function compile_xunsearch()
function compile_xunsearch()
{
    compile_libevent
    compile_scws
    compile_xapian_core_scws

    is_installed xunsearch $XUNSEARCH_BASE
    if [ "$?" = "0" ];then
        return;
    fi

    XUNSEARCH_CONFIGURE="
        configure_xunsearch_command
    "

    compile "xunsearch" "$XUNSEARCH_FILE_NAME" "xunsearch-$XUNSEARCH_VERSION/" "$XUNSEARCH_BASE" "XUNSEARCH_CONFIGURE" "after_xunsearch_make_install"
}
# }}}
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
    ./configure --prefix=$PKGCONFIG_BASE \
                --with-internal-glib
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

    local tmp_str=""
    if [ "$OS_NAME" != "darwin" ];then
        tmp_str="-Wl,--enable-new-dtags,-rpath,'\$(LIBRPATH)'"
    fi

    OPENSSL_CONFIGURE="
    ./config --prefix=$OPENSSL_BASE \
             --openssldir=$SSL_CONFIG_DIR \
             --libdir=lib \
             $tmp_str \
             threads shared -fPIC
    "
    # -darwin-i386-cc

    compile "openssl" "$OPENSSL_FILE_NAME" "openssl-$OPENSSL_VERSION" "$OPENSSL_BASE" "OPENSSL_CONFIGURE"

    curl https://curl.haxx.se/ca/cacert.pem -o $SSL_CONFIG_DIR/certs/ca-bundle.crt 1>/dev/null 2>&1
    $OPENSSL_BASE/bin/openssl dhparam -out $SSL_CONFIG_DIR/dhparams.pem 2048
}
# }}}
# {{{ function compile_icu()
function compile_icu()
{
    is_installed icu "$ICU_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    #export LD_LIBRARY_PATH
    ICU_CONFIGURE="
        configure_icu_command
    "

    compile "icu" "$ICU_FILE_NAME" "icu/source" "$ICU_BASE" "ICU_CONFIGURE"
    #export -n LD_LIBRARY_PATH
    if [ "$OS_NAME" = "darwin" ];then
        echo ""
        #repair_dynamic_shared_library $ICU_BASE/lib "libicu*dylib"
    fi

}
# }}}
# {{{ function compile_boost()
function compile_boost()
{
    compile_icu
    if [ "$OS_NAME" = "darwin" ];then
        compile_libuuid
    fi

    is_installed boost "$BOOST_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    #yum install python-devel bzip2-devel
    #yum install gperf libevent-devel

    echo_build_start boost

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
    if [ "$OS_NAME" = "darwin" ];then
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
    $( is_new_version $LIBZIP_VERSION 1.3.99 && \
        echo cmake . -DCMAKE_INSTALL_PREFIX=$LIBZIP_BASE || \
        echo ./configure --prefix=$LIBZIP_BASE --with-zlib=$ZLIB_BASE)
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
                $( [ "$OS_NAME" = "darwin" ] && echo "--without-lzma") \
                --without-python
    "
# xmlIO.c:1450:52: error: use of undeclared identifier 'LZMA_OK' mac上2.9.3报错. 加 --without-lzma
#或者 sed -n 's/LZMA_OK/LZMA_STREAM_END/p' xmlIO.c

    compile "libxml2" "$LIBXML2_FILE_NAME" "libxml2-$LIBXML2_VERSION" "$LIBXML2_BASE" "LIBXML2_CONFIGURE"
}
# }}}
# {{{ function compile_libwebp()
function compile_libwebp()
{
    compile_zlib
    compile_libjpeg
    compile_libpng

    is_installed libwebp "$LIBWEBP_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBWEBP_CONFIGURE="
        configure_libwebp_command
    "

    compile "libwebp" "$LIBWEBP_FILE_NAME" "libwebp-$LIBWEBP_VERSION" "$LIBWEBP_BASE" "LIBWEBP_CONFIGURE"

    #if [ "$OS_NAME" = "linux" ]; then
    #    repair_elf_file_rpath $LIBWEBP_BASE/bin/*webp*
    #fi
}
# }}}
# {{{ function compile_fribidi()
function compile_fribidi()
{
    is_installed fribidi "$FRIBIDI_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    FRIBIDI_CONFIGURE="
        configure_fribidi_command
    "

    compile "fribidi" "$FRIBIDI_FILE_NAME" "fribidi-$FRIBIDI_VERSION" "$FRIBIDI_BASE" "FRIBIDI_CONFIGURE"
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
    if [ "$OS_NAME" = "darwin" ];then
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
# {{{ function compile_libwbxml()
function compile_libwbxml()
{
    is_installed libwbxml "$LIBWBXML_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBWBXML_CONFIGURE="
        cmake ../libwbxml-${LIBWBXML_VERSION}/ \
              -DCMAKE_INSTALL_PREFIX=$LIBWBXML_BASE
    "

    mkdir libwbxml-${LIBWBXML_VERSION}-build

    compile "libwbxml" "$LIBWBXML_FILE_NAME" "libwbxml-${LIBWBXML_VERSION}-build" "$LIBWBXML_BASE" "LIBWBXML_CONFIGURE"


    if [ "$OS_NAME" = "linux" ]; then
        repair_elf_file_rpath $LIBWBXML_BASE/bin/wbxml2xml
        repair_elf_file_rpath $LIBWBXML_BASE/bin/xml2wbxml
    fi

    rm -rf libwbxml-${LIBWBXML_VERSION}
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
# {{{ function compile_patchelf()
function compile_patchelf()
{
    is_installed patchelf "$PATCHELF_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    PATCHELF_CONFIGURE="
    configure_patchelf_command
    "

    compile "patchelf" "$PATCHELF_FILE_NAME" "patchelf-${PATCHELF_VERSION}" "$PATCHELF_BASE" "PATCHELF_CONFIGURE"
}
# }}}
# {{{ function compile_tesseract()
function compile_tesseract()
{
    is_installed tesseract "$TESSERACT_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    TESSERACT_CONFIGURE="
        ./configure --prefix=$TESSERACT_BASE
    "

    compile "tesseract" "$TESSERACT_FILE_NAME" "tesseract-${TESSERACT_VERSION}" "$TESSERACT_BASE" "TESSERACT_CONFIGURE"
}
# }}}
# {{{ function compile_readline()
function compile_readline()
{
    is_installed readline "$READLINE_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    READLINE_CONFIGURE="
        ./configure --prefix=$READLINE_BASE \
                    --enable-multibyte \
                    --with-curses
    "

    compile "readline" "$READLINE_FILE_NAME" "readline-${READLINE_VERSION}" "$READLINE_BASE" "READLINE_CONFIGURE"
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
    if [ "$OS_NAME" = "linux" ]; then
        repair_elf_file_rpath $JPEG_BASE/bin/cjpeg
        repair_elf_file_rpath $JPEG_BASE/bin/djpeg
        repair_elf_file_rpath $JPEG_BASE/bin/jpegtran
        repair_elf_file_rpath $JPEG_BASE/bin/rdjpgcom
        repair_elf_file_rpath $JPEG_BASE/bin/wrjpgcom
    fi
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
        configure_poppler_command
    "

    compile "poppler" "$POPPLER_FILE_NAME" "poppler-$POPPLER_VERSION" "$POPPLER_BASE" "POPPLER_CONFIGURE"
}
# }}}
# {{{ configure_poppler_command()
configure_poppler_command()
{
    CPPFLAGS="$(get_cppflags $ZLIB_BASE/include $LIBPNG_BASE/include $LIBJPEG_BASE/include $OPENJPEG_BASE/include $CAIRO_BASE/include $FONTFORGE_BASE/include)"
    LDFLAGS="$(get_ldflags $ZLIB_BASE/lib $LIBPNG_BASE/lib $LIBJPEG_BASE/lib $OPENJPEG_BASE/lib $CAIRO_BASE/lib $FONTFORGE_BASE/lib)"

    if is_new_version $POPPLER_VERSION "0.60.0" ; then
        cmake . -DCMAKE_INSTALL_PREFIX=$POPPLER_BASE \
                -DCMAKE_BUILD_TYPE=release \
                -DCMAKE_CXX_FLAGS="$CPPFLAGS" \
                -DCMAKE_LD_FLAGS="$LDFLAGS"
    else
        CPPFLAGS="$CPPFLAGS" \
        LDFLAGS="$LDFLAGS" \
        ./configure --prefix=$POPPLER_BASE \
                    --enable-xpdf-headers
    fi
}
# }}}
# {{{ function compile_cairo()
function compile_cairo()
{
    compile_zlib
    compile_libpng
    compile_pixman
    compile_libX11
    compile_libXext
    [ "$OS_NAME" != "darwin" ] && compile_glib
    compile_fontconfig

    is_installed cairo "$CAIRO_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    CAIRO_CONFIGURE="
        configure_cairo_command
    "

    compile "cairo" "$CAIRO_FILE_NAME" "cairo-$CAIRO_VERSION" "$CAIRO_BASE" "CAIRO_CONFIGURE"
}
# }}}
# {{{ configure_cairo_command()
configure_cairo_command()
{
    CPPFLAGS="$(get_cppflags $ZLIB_BASE/include)" LDFLAGS="$(get_ldflags $ZLIB_BASE/lib)" \
     ./configure --prefix=$CAIRO_BASE \
                 --disable-dependency-tracking
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
     cmake ./ -DCMAKE_INSTALL_PREFIX=$OPENJPEG_BASE \
              -DCMAKE_BUILD_TYPE=Release \
              -DBUILD_THIRDPARTY=ON
    "

    compile "openjpeg" "$OPENJPEG_FILE_NAME" "openjpeg-$OPENJPEG_VERSION" "$OPENJPEG_BASE" "OPENJPEG_CONFIGURE"

    if [ "$OS_NAME" = "linux" ]; then
        for i in `find $OPENJPEG_BASE/bin/ -name "opj_*" -type f`;
        do
            repair_elf_file_rpath $i;
        done
    fi
}
# }}}
# {{{ function compile_fontforge()
function compile_fontforge()
{
    # yum install -y libtool-ltdl libtool-ltdl-devel patch
    #compile_pkgconfig
    # libspiro libuninameslist
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

    compile "fontforge" "$FONTFORGE_FILE_NAME" "fontforge-*${FONTFORGE_VERSION}" "$FONTFORGE_BASE" "FONTFORGE_CONFIGURE"
    export PATH="$old_path"
}
# }}}
# {{{ function compile_pango()
function compile_pango()
{
    compile_cairo
    [ "$OS_NAME" != "darwin" ] && compile_glib
    compile_fribidi
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
        configure_memcached_command
    "

    compile "memcached" "$MEMCACHED_FILE_NAME" "memcached-$MEMCACHED_VERSION" "$MEMCACHED_BASE" "MEMCACHED_CONFIGURE"
}
# }}}
# {{{ function configure_memcached_command()
function configure_memcached_command()
{
    # 没有configure
    if [ ! -f "./configure" ]; then
        # 执行报错，就只能下载有configure的包了
        ./autogen.sh
        if [ "$?" != "0" ];then
            return 1;
        fi
    fi

    ./configure --prefix=$MEMCACHED_BASE \
                --with-libevent=$LIBEVENT_BASE \
                $( echo "$HOST_TYPE"|grep -q x86_64 && echo "--enable-64bit" )
                # --enable-dtrace
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
        if [ "$OS_NAME" = "linux" ] ; then
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
                --without-mysql \
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
    ./configure --prefix=$EXPAT_BASE \
                --without-docbook
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
        configure_libpng_command
    "
    # --with-libpng-prefix

    compile "libpng" "$LIBPNG_FILE_NAME" "libpng-$LIBPNG_VERSION" "$LIBPNG_BASE" "LIBPNG_CONFIGURE"
}
# }}}
# {{{ configure_libpng_command()
configure_libpng_command()
{
    CPPFLAGS="$(get_cppflags $ZLIB_BASE/include)" LDFLAGS="$(get_ldflags $ZLIB_BASE/lib)" \
    ./configure --prefix=$LIBPNG_BASE \
                # --with-zlib-prefix=$ZLIB_BASE
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
#--enable-json1 \
#--enable-session \
#--enable-fts5

    compile "sqlite" "$SQLITE_FILE_NAME" "sqlite-autoconf-$SQLITE_VERSION" "$SQLITE_BASE" "SQLITE_CONFIGURE"
}
# }}}
# {{{ function compile_curl()
function compile_curl()
{
    compile_zlib
    compile_openssl
    compile_nghttp2

    is_installed curl "$CURL_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    CURL_CONFIGURE="
        configure_curl_command
    "
    # --disable-debug --enable-optimize

    compile "curl" "$CURL_FILE_NAME" "curl-$CURL_VERSION" "$CURL_BASE" "CURL_CONFIGURE"

    if [ "$OS_NAME" = "linux" ]; then
        for i in `find $CURL_BASE/lib/libcurl*.so* -type f`;
        do
            repair_elf_file_rpath $i;
        done
    fi
}
# }}}
# {{{ function compile_nghttp2()
function compile_nghttp2()
{
    compile_zlib
    compile_openssl
    compile_libevent
    compile_libxml2
    compile_boost

    is_installed nghttp2 "$NGHTTP2_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    NGHTTP2_CONFIGURE="
        ./configure --prefix=$NGHTTP2_BASE \
                    --with-libxml2 \
                    $( has_systemd && echo "--with-systemd" ) \
                    --with-boost=$BOOST_BASE
    "
                    # --with-jemalloc \

    compile "nghttp2" "$NGHTTP2_FILE_NAME" "nghttp2-$NGHTTP2_VERSION" "$NGHTTP2_BASE" "NGHTTP2_CONFIGURE"

    if [ "$OS_NAME" = "linux" ]; then
        :
        #for i in `find $NGHTTP2_BASE/lib/libnghttp2*.so* -type f`;
        #do
        #    repair_elf_file_rpath $i;
        #done
    fi
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
                $( is_new_version $FREETYPE_VERSION 2.9.1 && echo '--enable-freetype-config') \
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
    [ "$OS_NAME" != "darwin" ] && compile_glib
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
    if [ "$OS_NAME" = "darwin" ];then
        :
        #repair_dynamic_shared_library $HARFBUZZ_BASE/lib "libharfbuzz*dylib"
    fi

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
    # compile_fam
    #ftp://oss.sgi.com/projects/fam/download/stable/
    #ftp://oss.sgi.com/projects/fam/download/stable/fam-2.7.0.tar.gz

    if [ "$OS_NAME" != "darwin" ]; then
        compile_util_linux
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
        ./configure --prefix=$UTIL_LINUX_BASE \
                    --with-libiconv-prefix=$LIBICONV_BASE \
                    $( has_systemd && echo "--with-systemd" )
    "

    compile "util-linux" "$UTIL_LINUX_FILE_NAME" "util-linux-$UTIL_LINUX_VERSION" "$UTIL_LINUX_BASE" "UTIL_LINUX_CONFIGURE"
}
# }}}
# {{{ function compile_xproto()
function compile_xproto()
{
    # compile_macros

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
#    if [ "$OS_NAME" = 'darwin' ];then
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
# {{{ function compile_libXext()
function compile_libXext()
{
    is_installed libXext "$LIBXEXT_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBXEXT_CONFIGURE="
    ./configure --prefix=$LIBXEXT_BASE
    "

    compile "libXext" "$LIBXEXT_FILE_NAME" "libXext-$LIBXEXT_VERSION" "$LIBXEXT_BASE" "LIBXEXT_CONFIGURE"
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
            echo "yum install openssl.x86_64 openssl-devel.x86_64 openssl-libs.x86_64 openssl-static.x86_64" >&2
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
    local ext="so"
    if [ "$OS_NAME" = "darwin" ]; then
        local os_type="osx"
        local ext="dylib"
    fi

    local tmp1_64=""
    if [ -f "/usr/lib64/libkrb5.${ext}" ]; then
        KERBEROS_BASE="/usr"
        local tmp1_64="64"
    elif [ -d "/usr/local/Cellar/openssl" ]; then
        local tmp=`find /usr/local/Cellar/openssl -name libssl.pc|sed -n '1p'`;
        if [ ! -z "$tmp" -a -f "$tmp" ];then
            tmp=`dirname "$tmp"|xargs dirname`;
            tmp1_64=$( basename $tmp|sed -n 's/lib//p')
            KERBEROS_BASE=`dirname $tmp`;
        fi
    elif [ -f "/usr/lib/libkrb5.${ext}" ]; then
        KERBEROS_BASE="/usr"
        local tmp1_64=""
    elif [ -f "/usr/local/lib64/libkrb5.${ext}" ]; then
        KERBEROS_BASE="/usr/local"
        local tmp1_64="64"
    elif [ -f "/usr/local/lib/libkrb5.${ext}" ]; then
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
    compile_expat
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
                --with-expat=$EXPAT_BASE \
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
    if [ "$OS_NAME" = "darwin" ];then
        compile_libuuid
    fi
    compile_zlib
    compile_readline
    compile_libxml2
    compile_libxslt
    compile_openssl
    compile_gettext

    is_installed postgresql "$POSTGRESQL_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    POSTGRESQL_CONFIGURE="
        configure_postgresql_command
    "

    compile "postgresql" "$POSTGRESQL_FILE_NAME" "postgresql-$POSTGRESQL_VERSION" "$POSTGRESQL_BASE" "POSTGRESQL_CONFIGURE"
}
# }}}
# {{{ function compile_pgbouncer()
function compile_pgbouncer()
{
    if [ "$OS_NAME" = "darwin" ];then
        compile_libuuid
    fi
    compile_libevent

    is_installed pgbouncer "$PGBOUNCER_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    PGBOUNCER_CONFIGURE="
        ./configure --prefix=$PGBOUNCER_BASE \
                    --with-libevent=$LIBEVENT_BASE \
                    --without-openssl
    "

    compile "pgbouncer" "$PGBOUNCER_FILE_NAME" "pgbouncer-$PGBOUNCER_VERSION" "$PGBOUNCER_BASE" "PGBOUNCER_CONFIGURE"

    if [ "$OS_NAME" = "linux" ]; then
        repair_elf_file_rpath $PGBOUNCER_BASE/bin/pgbouncer
    fi
}
# }}}
# {{{ function compile_apache()
function compile_apache()
{
    compile_nghttp2
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
                --enable-modules=few \
                --enable-mods-static=few \
                --enable-so \
                --enable-rewrite \
                --enable-http \
                --enable-session \
                --enable-mime-magic \
                --enable-sed \
                --enable-ssl \
                --with-ssl=$OPENSSL_BASE \
                --with-apr=$APR_BASE \
                --with-apr-util=$APR_UTIL_BASE \
                --with-nghttp2=$NGHTTP2_BASE \
                --with-pcre=$PCRE_BASE/bin/pcre-config
    "
                #--enable-http2 \

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

    compile_libmaxminddb

    NGINX_CONFIGURE="
        configure_nginx_command
    "

    decompress $PCRE_FILE_NAME && decompress $ZLIB_FILE_NAME && decompress $OPENSSL_FILE_NAME && \
    decompress $NGINX_UPLOAD_PROGRESS_MODULE_FILE_NAME && \
    decompress $NGINX_PUSH_STREAM_MODULE_FILE_NAME && \
    decompress $NGINX_HTTP_GEOIP2_MODULE_FILE_NAME && \
    #decompress $NGINX_STICKY_MODULE_FILE_NAME && \
    #decompress $NGINX_UPLOAD_MODULE_FILE_NAME
    if [ "$?" != "0" ];then
        # return 1;
        exit 1;
    fi

    compile "nginx" "$NGINX_FILE_NAME" "nginx-$NGINX_VERSION" "$NGINX_BASE" "NGINX_CONFIGURE"

    /bin/rm -rf pcre-$PCRE_VERSION
    /bin/rm -rf zlib-$ZLIB_VERSION
    /bin/rm -rf openssl-$OPENSSL_VERSION
    /bin/rm -rf nginx-upload-progress-module-${NGINX_UPLOAD_PROGRESS_MODULE_VERSION}
    /bin/rm -rf nginx-push-stream-module-${NGINX_PUSH_STREAM_MODULE_VERSION}
    /bin/rm -rf ngx_http_geoip2_module-${NGINX_HTTP_GEOIP2_MODULE_VERSION}
    #/bin/rm -rf nginx-upload-module-${NGINX_UPLOAD_MODULE_VERSION}
    #/bin/rm -rf ${NGINX_STICKY_MODULE_FILE_NAME%%.*}

    init_nginx_conf
}
# }}}
# {{{ function compile_libuuid()
function compile_libuuid()
{
    is_installed libuuid "$LIBUUID_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBUUID_CONFIGURE="
    ./configure --prefix=$LIBUUID_BASE
                "

    compile "libuuid" "$LIBUUID_FILE_NAME" "libuuid-$LIBUUID_VERSION" "$LIBUUID_BASE" "LIBUUID_CONFIGURE"
}
# }}}
# {{{ function compile_rsyslog()
function compile_rsyslog()
{
    if [ "$OS_NAME" = "darwin" ];then
        compile_libuuid
    fi
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
        configure_rsyslog_command
    "

    compile "rsyslog" "$RSYSLOG_FILE_NAME" "rsyslog-$RSYSLOG_VERSION" "$RSYSLOG_BASE" "RSYSLOG_CONFIGURE" "after_rsyslog_make_install"

}
# }}}
# {{{ function after_rsyslog_make_install()
function after_rsyslog_make_install()
{
    mkdir -p $RSYSLOG_CONFIG_DIR
    cp ./platform/redhat/rsyslog.conf $RSYSLOG_CONFIG_DIR/
    init_rsyslog_conf
}
# }}}
# {{{ function configure_rsyslog_command()
function configure_rsyslog_command()
{
    if [ "$OS_NAME" = "darwin" ];then
        for i in `grep -rl 'whole-archive' ./`;
        do
            sed -i.bak$$ -e 's/--whole-archive/-all_load/g' $i;
            sed -i.bak$$ -e 's/--no-whole-archive/-noall_load/g' $i;
            sed -i.bak$$ -e 's/no-whole-archive/noall_load/g' $i;
        done
        find . -name "*.bak*" -delete
    fi
    #PATH="${CONTRIB_BASE}/bin:$PATH" \
    #PKG_CONFIG_PATH="${CONTRIB_BASE}/lib/pkgconfig"
    ./configure --prefix=$RSYSLOG_BASE \
                --sysconfdir=$RSYSLOG_CONFIG_DIR \
                $( has_systemd && echo "--with-systemdsystemunitdir=$RSYSLOG_BASE/systemd" ) \
                --enable-elasticsearch \
                $(is_installed_mysql && echo --enable-mysql ) \
                --enable-mail

        # No package 'systemd' found

        # --enable-libgcrypt

        # error: Net-SNMP is missing
        # --enable-snmp \
}
# }}}
# {{{ function compile_logrotate()
function compile_logrotate()
{
    is_installed logrotate "$LOGROTATE_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LOGROTATE_CONFIGURE="
        configure_logrotate_command
    "

    compile "logrotate" "$LOGROTATE_FILE_NAME" "logrotate-$LOGROTATE_VERSION" "$LOGROTATE_BASE" "LOGROTATE_CONFIGURE" "after_logrotate_make_install"
}
# }}}
# {{{ function after_logrotate_make_install()
function after_logrotate_make_install()
{
    init_logrotate_conf
}
# }}}
# {{{ function configure_logrotate_command()
function configure_logrotate_command()
{
    ./configure --prefix=$LOGROTATE_BASE \
                --sysconfdir=$LOGROTATE_CONFIG_DIR \
                --with-state-file-path=$LOGROTATE_STATE_FILE

                #--with-state-file-path=PATH path to state file (/var/lib/logrotate.status by default)
                #--with-default-mail-command=COMMAND default mail command (e.g. /bin/mail -s)
                #--with-compress-command=COMMAND compress command (default: /bin/gzip)
                #--with-uncompress-command=COMMAND uncompress command (default: /bin/gunzip)
                #--with-compress-extension=EXTENSION compress extension (default: .gz)

                # --with-acl
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
    compile_libjpeg
    compile_libwebp
    compile_libXpm

    is_installed libgd "$LIBGD_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    # CPPFLAGS="$(get_cppflags ${ZLIB_BASE}/include ${LIBPNG_BASE}/include ${LIBICONV_BASE}/include ${FREETYPE_BASE}/include ${FONTCONFIG_BASE}/include ${JPEG_BASE}/include $([ "$OS_NAME" = 'darwin' ] && echo " $LIBX11_BASE/include") )" \
    # LDFLAGS="$(get_ldflags ${ZLIB_BASE}/lib ${LIBPNG_BASE}/lib ${LIBICONV_BASE}/lib ${FREETYPE_BASE}/lib ${FONTCONFIG_BASE}/lib ${JPEG_BASE}/lib $([ "$OS_NAME" = 'darwin' ] && echo " $LIBX11_BASE/lib") )" \
    LIBGD_CONFIGURE="
    ./configure --prefix=$LIBGD_BASE \
                --with-libiconv-prefix=$LIBICONV_BASE \
                --with-zlib=$ZLIB_BASE \
                --with-png=$LIBPNG_BASE \
                --with-freetype=$FREETYPE_BASE \
                --with-fontconfig=$FONTCONFIG_BASE \
                --with-xpm=$LIBXPM_BASE \
                --with-webp=$LIBWEBP_BASE \
                --with-jpeg=$LIBJPEG_BASE
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
    #compile_jpeg
    compile_libjpeg
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
    if [ "$OS_NAME" != "darwin" ]; then
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
    if [ "$OS_NAME" = "darwin" ];then
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
    cmake -DCMAKE_INSTALL_PREFIX=$RABBITMQ_C_BASE \
          -DCMAKE_INSTALL_LIBDIR=$RABBITMQ_C_BASE/lib
    "

    compile "rabbitmq-c" "$RABBITMQ_C_FILE_NAME" "rabbitmq-c-${RABBITMQ_C_VERSION}" "$RABBITMQ_C_BASE" "RABBITMQ_C_CONFIGURE"
}
# }}}
# {{{ function compile_python()
function compile_python()
{
    #compile_expat
    #compile_libxml2
    compile_openssl
    compile_sqlite
    compile_zlib
    compile_readline

    is_installed python "$PYTHON_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    PYTHON_CONFIGURE="
        configure_python_command
    "

    compile "python" "$PYTHON_FILE_NAME" "Python-$PYTHON_VERSION" "$PYTHON_BASE" "PYTHON_CONFIGURE" "after_python_make_install"
}
# }}}
# {{{ function after_python_make_install()
function after_python_make_install()
{
    $PYTHON_BASE/bin/pip3 install --upgrade pip
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
    [ `echo "$PHP_VERSION 7.1.999"|tr " " "\n"|sort -rV|head -1` != "$PHP_VERSION" ] && compile_libmcrypt
    compile_curl
    compile_gmp
    compile_libgd
    compile_freetype
    #compile_jpeg
    compile_libjpeg
    compile_libpng
    compile_libXpm
    compile_libwebp

    is_installed php "$PHP_BASE"
    if [ "$?" = "0" ];then
        PHP_EXTENSION_DIR="$( find $PHP_LIB_DIR -name "no-debug-*" )"
        return;
    fi

    PHP_CONFIGURE="
        configure_php_command
    "

    compile "php" "$PHP_FILE_NAME" "php-$PHP_VERSION" "$PHP_BASE" "PHP_CONFIGURE" "after_php_make_install"


    # browscap 支持处理
    # 打开browscap后，只要执行php就会卡，不管用没用get_browser()函数
    mkdir $PHP_CONFIG_DIR/extra && \
    cp $BROWSCAP_INI_FILE_NAME $PHP_CONFIG_DIR/extra/browscap.ini
    if [ "$?" != "0" ];then
        echo "Warning: browscp.ini copy faild." >&2
        return;
    fi
    local pattern='^[; ]\{0,\}\(browscap \{0,\}= \).\{1,\}$';
    change_php_ini "$pattern" "\1$(sed_quote $PHP_CONFIG_DIR/extra/browscap.ini)"
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

    mkdir -p $SBIN_DIR
    cp sapi/fpm/init.d.php-fpm $SBIN_DIR/php-fpm

    chmod u+x $SBIN_DIR/php-fpm

    mkdir -p $BASE_DIR/setup/service
    cp sapi/fpm/php-fpm.service $BASE_DIR/setup/service/php-fpm.service

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

    is_installed_php_extension intl 1
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_INTL_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --enable-intl --with-icu-dir=$ICU_BASE
    "
    compile "php_extension_intl" "$PHP_FILE_NAME" "php-$PHP_VERSION/ext/intl/" "intl.so" "PHP_EXTENSION_INTL_CONFIGURE"
    if [ "$OS_NAME" = "darwin" ];then
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

    is_installed_php_extension pdo_pgsql 1
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_PDO_PGSQL_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --with-pdo-pgsql=$POSTGRESQL_BASE
    "
    compile "php_extension_pdo_pgsql" "$PHP_FILE_NAME" "php-$PHP_VERSION/ext/pdo_pgsql/" "pdo_pgsql.so" "PHP_EXTENSION_PDO_PGSQL_CONFIGURE"
}
# }}}
# {{{ function compile_php_extension_apcu()
function compile_php_extension_apcu()
{
    is_installed_php_extension apcu $APCU_VERSION
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_APCU_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --enable-apcu \
                --enable-apcu-clear-signal \
                --enable-apcu-spinlocks
    "
                # --enable-coverage
    compile "php_extension_apcu" "$APCU_FILE_NAME" "apcu-$APCU_VERSION" "apcu.so" "PHP_EXTENSION_APCU_CONFIGURE" "after_php_extension_apcu_make_install"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function after_php_extension_apcu_make_install()
function after_php_extension_apcu_make_install()
{
    mkdir -p $BASE_DIR/inc/apcu
    if [ "$?" != "0" ];then
        echo "mkdir faild. command: mkdir -p $BASE_DIR/inc/apcu" >&2
        return 1;
    fi
    cp apc.php $BASE_DIR/inc/apcu/
    if [ "$?" != "0" ];then
        echo " copy file faild. command: cp apc.php $BASE_DIR/inc/apcu/" >&2
        return 1;
    fi

    if grep -q 'apc\.rfc1867' $php_ini ; then
        return 0;
    fi

    echo '[apcu]' >> $php_ini
    echo 'apc.rfc1867 = 1' >> $php_ini
}
# }}}
# {{{ function compile_php_extension_apcu_bc()
function compile_php_extension_apcu_bc()
{
    compile_php_extension_apcu

    is_installed_php_extension apc $APCU_BC_VERSION
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
    is_installed_php_extension yaf $YAF_VERSION
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

    is_installed_php_extension phalcon $PHALCON_VERSION
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
    is_installed_php_extension xdebug $XDEBUG_VERSION
    if [ "$?" = "0" ];then
        return;
    fi

    # cp contrib/xt.vim ~/.vim/bundle/

    PHP_EXTENSION_XDEBUG_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --enable-xdebug
    "
    compile "php_extension_xdebug" "$XDEBUG_FILE_NAME" "xdebug-$XDEBUG_VERSION" "xdebug.so" "PHP_EXTENSION_XDEBUG_CONFIGURE"
    sed -i.bak.$$ 's/^\(extension=xdebug\.so\)$/zend_\1/' $php_ini
    rm_bak_file ${php_ini}.bak.*

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_raphf()
function compile_php_extension_raphf()
{
    is_installed_php_extension raphf $RAPHF_VERSION
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
    is_installed_php_extension propro $PROPRO_VERSION
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
    compile_zlib
    compile_curl
    compile_libevent
    compile_icu
    compile_php
    compile_php_extension_raphf

    is_installed_php_extension http $PECL_HTTP_VERSION
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_PECL_HTTP_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --with-http \
                --with-http-zlib-dir=$ZLIB_BASE \
                --with-http-libcurl-dir=$CURL_BASE \
                --with-http-libicu-dir=$ICU_BASE
                --with-http-libevent-dir=$LIBEVENT_BASE
    "
                # --with-http-libidn-dir=

    compile "php_extension_pecl_http" "$PECL_HTTP_FILE_NAME" "pecl_http-$PECL_HTTP_VERSION" "http.so" "PHP_EXTENSION_PECL_HTTP_CONFIGURE"

    /bin/rm -rf package.xml

    if [ "$OS_NAME" = "darwin" ];then
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

    is_installed_php_extension amqp $AMQP_VERSION
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
    is_installed_php_extension mailparse $MAILPARSE_VERSION
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
    is_installed_php_extension redis $PHP_REDIS_VERSION
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

    is_installed_php_extension gearman $PHP_GEARMAN_VERSION

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

    is_installed_php_extension mongodb $PHP_MONGODB_VERSION
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

    is_installed_php_extension solr $SOLR_VERSION
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

    is_installed_php_extension memcached $PHP_MEMCACHED_VERSION
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
    is_installed_php_extension pthreads $PTHREADS_VERSION
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
# {{{ function compile_php_extension_scws()
function compile_php_extension_scws()
{
    compile_scws

    is_installed_php_extension scws $SCWS_VERSION
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_SCWS_CONFIGURE="
        ./configure --with-php-config=$PHP_BASE/bin/php-config \
                    --with-scws=$SCWS_BASE
    "

    compile "php_extension_scws" "$SCWS_FILE_NAME" "scws-$SCWS_VERSION/phpext" "scws.so" "PHP_EXTENSION_SCWS_CONFIGURE"

    #配置
    #[scws]
    # scws.default.charset = gbk
    # scws.default.fpath = $BASE_DIR/etc/scws
}
# }}}
# {{{ function compile_php_extension_zip()
function compile_php_extension_zip()
{
    compile_libzip

    is_installed_php_extension zip $ZIP_VERSION
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_ZIP_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --enable-zip \
                --with-libzip=$LIBZIP_BASE
    "

    compile "php_extension_zip" "$ZIP_FILE_NAME" "zip-$ZIP_VERSION" "zip.so" "PHP_EXTENSION_ZIP_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_swoole()
function compile_php_extension_swoole()
{
    compile_openssl
    compile_pcre
    compile_hiredis
    compile_nghttp2

    is_installed_php_extension swoole $SWOOLE_VERSION
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
# {{{ function compile_php_extension_protobuf()
function compile_php_extension_protobuf()
{
    is_installed_php_extension protobuf $PHP_PROTOBUF_VERSION
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_PROTOBUF_CONFIGURE="
        ./configure --with-php-config=$PHP_BASE/bin/php-config \
                    --enable-protobuf
    "

    compile "php_extension_protobuf" "$PHP_PROTOBUF_FILE_NAME" "protobuf-$PHP_PROTOBUF_VERSION" "protobuf.so" "PHP_EXTENSION_PROTOBUF_CONFIGURE"
}
# }}}
# {{{ function compile_php_extension_grpc()
function compile_php_extension_grpc()
{
    compile_zlib
    is_installed_php_extension grpc $PHP_GRPC_VERSION
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_GRPC_CONFIGURE="
        configure_php_ext_grpc_command
    "

    compile "php_extension_grpc" "$PHP_GRPC_FILE_NAME" "grpc-$PHP_GRPC_VERSION" "grpc.so" "PHP_EXTENSION_GRPC_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function configure_php_ext_grpc_command()
function configure_php_ext_grpc_command()
{
    CPPFLAGS="$(get_cppflags $ZLIB_BASE/include)" LDFLAGS="$(get_ldflags $ZLIB_BASE/lib)" \
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --enable-grpc

}
# }}}
# {{{ function compile_php_extension_qrencode()
function compile_php_extension_qrencode()
{
    compile_qrencode

    is_installed_php_extension qrencode $PHP_QRENCODE_VERSION
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_QRENCODE_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config --with-qrencode=$QRENCODE_BASE
    "

    # $PHP_BASE/bin/phpize --clean
    compile "php_extension_qrencode" "$PHP_QRENCODE_FILE_NAME" "qrencode-$PHP_QRENCODE_VERSION" "qrencode.so" "PHP_EXTENSION_QRENCODE_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function compile_php_extension_dio()
function compile_php_extension_dio()
{
    is_installed_php_extension dio $DIO_VERSION
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

    is_installed_php_extension event $EVENT_VERSION
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

    is_installed_php_extension libevent $PHP_LIBEVENT_VERSION
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

    is_installed_php_extension imagick $IMAGICK_VERSION
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

    is_installed_php_extension zmq $PHP_ZMQ_VERSION
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

    is_installed_php_extension $( is_new_version 7.1.99 $PHP_VERSION && echo 'lib')sodium $( is_new_version 7.1.99 $PHP_VERSION && echo $PHP_LIBSODIUM_VERSION || echo 1)
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_LIBSODIUM_CONFIGURE="
        configure_php_ext_libsodium_command
    "

    local file_name="$PHP_LIBSODIUM_FILE_NAME"
    local dir_name="libsodium-$PHP_LIBSODIUM_VERSION"
    local ext_name="$( is_new_version 7.1.99 $PHP_VERSION && echo 'lib')sodium.so"
    if [ `echo "${PHP_VERSION}" "7.1.99"|tr " " "\n"|sort -rV|head -1` != "7.1.99" ]; then
        file_name="${PHP_FILE_NAME}"
        dir_name="php-${PHP_VERSION}/ext/sodium"
        #ext_name="sodium.so"
    fi
    compile "php_extension_libsodium" "$file_name" "$dir_name" "$ext_name" "PHP_EXTENSION_LIBSODIUM_CONFIGURE"

    /bin/rm -rf package.xml
}
# }}}
# {{{ function configure_php_libsodium_command()
function configure_php_ext_libsodium_command()
{
    CPPFLAGS="$(get_cppflags $LIBSODIUM_BASE/include)" \
    LDFLAGS="$(get_ldflags $LIBSODIUM_BASE/lib)" \
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --with-$( is_new_version 7.1.99 $PHP_VERSION && echo 'lib')sodium=$LIBSODIUM_BASE
}
# }}}
# {{{ function compile_php_extension_tidy()
function compile_php_extension_tidy()
{
    compile_tidy

    is_installed_php_extension tidy 1
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_TIDY_CONFIGURE="
    configure_php_tidy_command
    "

    compile "php_extension_tidy" "$PHP_FILE_NAME" "php-${PHP_VERSION}/ext/tidy" "tidy.so" "PHP_EXTENSION_TIDY_CONFIGURE"

    /bin/rm -rf package.xml
    if [ "$OS_NAME" = "darwin" ];then
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

    is_installed_php_extension imap 1
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_IMAP_CONFIGURE="
        configure_php_ext_imap_command
    "

    compile "php_extension_imap" "$PHP_FILE_NAME" "php-${PHP_VERSION}/ext/imap" "imap.so" "PHP_EXTENSION_IMAP_CONFIGURE"

    /bin/rm -rf package.xml
    if [ "$OS_NAME" = "darwin" ];then
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

    is_installed_php_extension sphinx $PHP_SPHINX_VERSION
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
        exit 1;
    fi

    #mysql 8.0.11 需要pcre2,而且也太费时间和空间(5G以上吧)，以后不编译了。

    #不编译源码
    if [ "$MYSQL_FILE_NAME" != "mysql-${MYSQL_VERSION}.tar.gz" ]; then

        mkdir -p $MYSQL_BASE

        cp -r ${MYSQL_FILE_NAME%%.tar.gz}/* $MYSQL_BASE/

        if [ "$?" != "0" ];then
            echo "install mysql faild. command: cp -r ${MYSQL_FILE_NAME%%.tar.gz}/* $MYSQL_BASE/" >&2
            exit 1;
        fi

        /bin/rm -rf ${MYSQL_FILE_NAME%%.tar.gz}

        if [ "$?" != "0" ];then
            echo "install mysql faild. command: /bin/rm -rf ${MYSQL_FILE_NAME%%.tar.gz}" >&2
            exit 1;
        fi

        mkdir -p $MYSQL_CONFIG_DIR && cp $curr_dir/conf/my.cnf $mysql_cnf
        if [ "$?" != "0" ];then
            exit 1;
        fi

        init_mysql_cnf

        return;
    fi

    #编译源码
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

    #cmake .. -LH  # overview with help text
    #cmake .. -LAH
    #sudo yum install glibc-static*
    #sudo yum install ncurses-devel ncurses
    cmake ../mysql-$MYSQL_VERSION -DCMAKE_INSTALL_PREFIX=$MYSQL_BASE \
                                  -DSYSCONFDIR=$MYSQL_CONFIG_DIR \
                                  $( is_new_version $MYSQL_VERSION "7.999.0" && echo '' || echo '-DDEFAULT_CHARSET=utf8') \
                                  $( is_new_version $MYSQL_VERSION "7.999.0" && echo '' || echo '-DDEFAULT_COLLATION=utf8_general_ci') \
                                  $( [ "$OS_NAME" = "linux" ] && echo "-DENABLE_GPROF=ON" ) \
                                  -DWITH_SSL=$( is_new_version $MYSQL_VERSION "8.0.0" && echo "$OPENSSL_BASE" || echo "bundled") \
                                  -DWITH_BOOST=../boost_${BOOST_VERSION}/ \
                                  -DWITH_ZLIB=$ZLIB_BASE \
                                  -DWITH_CURL=$CURL_BASE \
                                  $( has_systemd && echo '-DWITH_SYSTEMD=ON' ) \
                                  -DINSTALL_MYSQLTESTDIR=

                                  # -DWITH_SSL=$OPENSSL_BASE \  # OPENSSL_VERSIOn > 1.1时，编译不过去
                                  # -DWITH_INNOBASE_STORAGE_ENGINE=1 \
                                  # -DWITH_PARTITION_STORAGE_ENGINE=1
                                  # -DWITH_INNODB_MEMCACHED=1 \ mac系统下编译不过去，报错
                                  # -DWITH_EXTRA_CHARSET:STRING=utf8,gbk \
                                  # -DWITH_READLINE=1 \
                                  # -DENABLED_LOCAL_INFILE=1 \                      #允许从本地导入数据

    #// Set to true if this is a community build
    #COMMUNITY_BUILD:BOOL=ON
    #// Enable profiling
    #ENABLED_PROFILING:BOOL=ON
    #// Enable gprof (optimized, Linux builds only)
    #ENABLE_GPROF:BOOL=OFF
    
    #// Enable SASL on InnoDB Memcached
    #ENABLE_MEMCACHED_SASL:BOOL=OFF

    #// Enable SASL on InnoDB Memcached
    #ENABLE_MEMCACHED_SASL_PWDB:BOOL=OFF

    #// Randomize the order of all symbols in the binary
    #LINK_RANDOMIZE:BOOL=OFF

    #// Seed to use for link randomization
    #LINK_RANDOMIZE_SEED:STRING=mysql

    #// default MySQL keyring directory
    #MYSQL_KEYRINGDIR:PATH=/usr/local/mysql/keyring

    #// Take extra pains to make build result independent of build location and time
    #REPRODUCIBLE_BUILD:BOOL=OFF

    #// Enable address sanitizer
    #WITH_ASAN:BOOL=OFF

    # Report error if the LDAP authentication plugin cannot be built.
    #WITH_AUTHENTICATION_LDAP:BOOL=OFF

    #WITH_INNODB_MEMCACHED:BOOL=OFF

    # Enable memory sanitizer
    #WITH_MSAN:BOOL=OFF

    # Enable thread sanitizer
    #WITH_TSAN:BOOL=OFF

    # Enable undefined behavior sanitizer
    #WITH_UBSAN:BOOL=OFF

    #WITH_UNIT_TESTS:BOOL=ON

    # Valgrind instrumentation
    #WITH_VALGRIND:BOOL=OFF

    make_run "$?/mysql"
    if [ "$?" != "0" ];then
        exit 1;
    fi

    #if [ -d "scripts/systemd" ]; then
    #    mkdir -p $BASE_DIR/setup/service && cp scripts/mysqld*.service $BASE_DIR/setup/service/
    #fi

    cd ..
    /bin/rm -rf mysql-$MYSQL_VERSION
    /bin/rm -rf $mysql_install
    /bin/rm -rf boost_$BOOST_VERSION

    mkdir -p $MYSQL_CONFIG_DIR && cp $curr_dir/conf/my.cnf $mysql_cnf
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

    is_installed qrencode "$QRENCODE_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    QRENCODE_CONFIGURE="
    ./configure --prefix=$QRENCODE_BASE \
                --with-libiconv-prefix=$LIBICONV_BASE
    "

    compile "qrencode" "$QRENCODE_FILE_NAME" "qrencode-$QRENCODE_VERSION" "$QRENCODE_BASE" "QRENCODE_CONFIGURE"
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
    # yum install nasm
    #compile_nasm

    is_installed libjpeg "$LIBJPEG_BASE"
    if [ "$?" = "0" ];then
        return;
    fi

    LIBJPEG_CONFIGURE="
        configure_libjpeg_command
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

    is_installed_php_extension maxminddb $MAXMIND_DB_READER_PHP_VERSION
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
    sed -i.bak.$$ "s/^# DatabaseDirectory .*$/DatabaseDirectory $(sed_quote2 $GEOIP2_DATA_DIR)/" $BASE_DIR/etc/GeoIP.conf
    if [ "$?" != "0" ]; then
        echo "mod $BASE_DIR/etc/GeoIP.conf faild." >&2;
        return 1;
    fi
    rm_bak_file $BASE_DIR/etc/GeoIP.conf.bak.*
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
# {{{ function install_dehydrated()
function install_dehydrated()
{
    echo_build_start "install_dehydrated"

    decompress $DEHYDRATED_FILE_NAME
    if [ "$?" != "0" ];then
        echo "decompress file error. file_name: $DEHYDRATED_FILE_NAME" >&2
        exit 1;
    fi

    mkdir -p $DEHYDRATED_CONFIG_DIR $DEHYDRATED_BASE/sbin $TMP_DATA_DIR/dehydrated
    if [ "$?" != "0" ];then
        echo "mkdir faild. command: mkdir -p $DEHYDRATED_CONFIG_DIR $DEHYDRATED_BASE/sbin $TMP_DATA_DIR/dehydrated" >&2
        exit 1;
    fi

    cp -f dehydrated-${DEHYDRATED_VERSION}/dehydrated $DEHYDRATED_BASE/sbin/ && \
    cp -f dehydrated-${DEHYDRATED_VERSION}/docs/examples/config $DEHYDRATED_CONFIG_DIR/ && \
    touch $DEHYDRATED_CONFIG_DIR/domains.txt
    #cp -f dehydrated-${DEHYDRATED_VERSION}/docs/examples/domains.txt $DEHYDRATED_CONFIG_DIR/

    if [ "$?" != "0" ];then
        echo "copy file faild. command: cp ...." >&2
        # return 1;
        exit 1;
    fi

    rm -rf dehydrated-${DEHYDRATED_VERSION}
    if [ "$?" != "0" ];then
        echo "delete dir faild. command: rm -rf dehydrated-${DEHYDRATED_VERSION}" >&2
        # return 1;
        exit 1;
    fi
    init_dehydrated_conf
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
#    is_installed zendFramework $ZEND_BASE
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
#    is_installed smarty $SMARTY_BASE
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
# {{{ function compile_htmlpurifier()
function compile_htmlpurifier()
{
#    is_installed htmlpurifier $HTMLPURIFIER_BASE
#    if [ "$?" = "0" ];then
#        return;
#    fi

    echo_build_start htmlpurifier
    decompress $HTMLPURIFIER_FILE_NAME
    mkdir -p $HTMLPURIFIER_BASE
    cp -r htmlpurifier-$HTMLPURIFIER_VERSION/library/* $HTMLPURIFIER_BASE
    /bin/rm -rf htmlpurifier-$HTMLPURIFIER_VERSION
}
# }}}
# {{{ function compile_composer()
function compile_composer()
{
    is_installed composer $COMPOSER_BASE

    echo_build_start composer
    decompress $COMPOSER_FILE_NAME
    mkdir -p $COMPOSER_BASE
    mkdir -p $BIN_DIR
    cp -r composer-$COMPOSER_VERSION/src/Composer $COMPOSER_BASE/
    cp composer-$COMPOSER_VERSION/bin/* $BIN_DIR/

    # 需要sed 处理bin/目录下的文件中包含文件的行

    /bin/rm -rf composer-$COMPOSER_VERSION
}
# }}}
# {{{ function compile_ckeditor()
function compile_ckeditor()
{
#    is_installed ckeditor $CKEDITOR_BASE
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
#    is_installed jquery $JQUERY_BASE
#    if [ "$?" = "0" ];then
#        return;
#    fi

    echo_build_start jquery

    mkdir -p $JQUERY_BASE

    cp $JQUERY_FILE_NAME $JQUERY_BASE/
    cp $JQUERY3_FILE_NAME $JQUERY_BASE/
}
# }}}
# {{{ function compile_d3()
function compile_d3()
{
#    is_installed d3 $D3_BASE
#    if [ "$?" = "0" ];then
#        return;
#    fi

    echo_build_start d3

    mkdir -p $D3_BASE

    decompress ${D3_FILE_NAME} d3-${D3_VERSION}
    if [ "$?" != "0" ];then
        # return 1;
        exit 1;
    fi

    cp d3-${D3_VERSION}/d3.min.js $D3_BASE/
    rm -rf d3-${D3_VERSION}
}
# }}}
# {{{ function compile_famous()
function compile_famous()
{
    echo_build_start famous
    mkdir -p $FAMOUS_BASE
    mkdir -p $CSS_BASE

    decompress ${FAMOUS_FILE_NAME}
    if [ "$?" != "0" ];then
        # return 1;
        exit 1;
    fi

    cp famous-${FAMOUS_VERSION}/dist/*.min.js $FAMOUS_BASE/
    cp famous-${FAMOUS_VERSION}/dist/*.css $CSS_BASE/
    rm -rf famous-${FAMOUS_VERSION}
}
# }}}
# {{{ function compile_chartjs()
function compile_chartjs()
{

    echo_build_start chartjs
    mkdir -p $CHARTJS_BASE

    decompress ${CHARTJS_FILE_NAME}
    if [ "$?" != "0" ];then
        # return 1;
        exit 1;
    fi

    cp Chart.js-${CHARTJS_VERSION}/dist/Chart.*min.js $CHARTJS_BASE/
    rm -rf Chart.js-${CHARTJS_VERSION}
}
# }}}
# {{{ function compile_famous_angular()
function compile_famous_angular()
{
    echo_build_start famous-angular
    mkdir -p $FAMOUS_BASE
    mkdir -p $CSS_BASE

    decompress ${FAMOUS_ANGULAR_FILE_NAME}
    if [ "$?" != "0" ];then
        # return 1;
        exit 1;
    fi

    cp famous-angular-${FAMOUS_ANGULAR_VERSION}/dist/famous-angular.min.js $FAMOUS_BASE/
    cp famous-angular-${FAMOUS_ANGULAR_VERSION}/dist/famous-angular.min.css $CSS_BASE/

}
# }}}
# {{{ configure command functions
# {{{ function configure_libjpeg_command()
function configure_libjpeg_command()
{
    if  is_new_version $LIBJPEG_VERSION 2.0.0 ; then
        cmake ./ -DCMAKE_INSTALL_PREFIX=$LIBJPEG_BASE \
                 -DCMAKE_INSTALL_LIBDIR=$LIBJPEG_BASE/lib
    else
        # 解决 ./configure: line 13431: PKG_PROG_PKG_CONFIG: command not found
        autoreconf -f -i  && \
        ./configure --prefix=$LIBJPEG_BASE
    fi
}
# }}}
# {{{ configure_xapian_core_scws_command()
configure_xapian_core_scws_command()
{
    # 不改，使用不上字典
    sed -i.bak "s#SCWS_ETCDIR=\"\{0,1\}\$SCWS_DIR/etc\"\{0,1\}#SCWS_ETCDIR=$(sed_quote2 $SCWS_CONFIG_DIR)#" configure

    ./configure --prefix=$XAPIAN_CORE_SCWS_BASE \
                --with-scws=$SCWS_BASE
}
# }}}
# {{{ configure_xunsearch_command()
configure_xunsearch_command()
{
    # 不改，使用不上字典
    sed -i.bak "s#SCWS_ETCDIR=\"\{0,1\}\$SCWS_DIR/etc\"\{0,1\}#SCWS_ETCDIR=$(sed_quote2 $SCWS_CONFIG_DIR)#" configure
    #1.4.11编译不过去。报libevent 版本不对
    sed -i.bak 's/_EVENT_NUMERIC_VERSION/EVENT__NUMERIC_VERSION/' configure

    #apc 换成apcu
    for i in `find sdk/php/ -name "*.php"`; do sed -i 's/apc_/apcu_/' $i; done

    ./configure --prefix=$XUNSEARCH_BASE \
                --with-scws=$SCWS_BASE \
                --sysconfdir=$BASE_DIR/etc/scws \
                --with-xapian=$XAPIAN_CORE_SCWS_BASE \
                --with-libevent=$LIBEVENT_BASE \
                --enable-memory-cache

    #--datadir=$BASE_DIR/data/xunsearch \
}
# }}}
# {{{ function after_xunsearch_make_install()
function after_xunsearch_make_install()
{
    mkdir -p $BASE_DIR/inc && \
        ln -s $XUNSEARCH_BASE/sdk/php/lib $BASE_DIR/inc/xunsearch

    if [ "$?" != "0" ];then
        echo " copy file faild. command: $cmd" >&2
        return 1;
    fi

    #mkdir -p $BASE_DIR/inc/xunsearch
    #if [ "$?" != "0" ];then
    #    echo "mkdir faild. command: mkdir -p $BASE_DIR/inc/xunsearch" >&2
    #    return 1;
    #fi

    #cp sdk/php/util/XSDataSource.class.php \
    #              sdk/php/util/XSUtil.class.php \
    #              sdk/php/lib/XS.php \
    #              $BASE_DIR/inc/xunsearch/"

    #if [ "$?" != "0" ];then
    #    echo " copy file faild. command: $cmd" >&2
    #    return 1;
    #fi
}
# }}}
# {{{ configure_libwebp_command()
configure_libwebp_command()
{

    ./autogen.sh && \
    CPPFLAGS="$(get_cppflags $ZLIB_BASE/include $LIBPNG_BASE/include $LIBJPEG_BASE/include)" \
    LDFLAGS="$(get_ldflags $ZLIB_BASE/lib $LIBPNG_BASE/lib $LIBJPEG_BASE/lib)" \
    ./configure --prefix=$LIBWEBP_BASE

    # cmake 编译后还没有libwebp.pc文件 ,没有.so文件
    #CPPFLAGS="$(get_cppflags $ZLIB_BASE/include $LIBPNG_BASE/include $LIBJPEG_BASE/include)" \
    #LDFLAGS="$(get_ldflags $ZLIB_BASE/lib $LIBPNG_BASE/lib $LIBJPEG_BASE/lib)" \
    #cmake . -DCMAKE_INSTALL_PREFIX=$LIBWEBP_BASE \
    #        -DWEBP_BUILD_CWEBP=ON \
    #        -DWEBP_BUILD_DWEBP=ON \
    #        -DWEBP_BUILD_GIF2WEBP=ON \
    #        -DWEBP_BUILD_IMG2WEBP=ON \
    #        -DWEBP_BUILD_WEBPINFO=ON
}
# }}}
# {{{ configure_fribidi_command()
configure_fribidi_command()
{
    ./autogen.sh --prefix=$FRIBIDI_BASE --disable-docs
}
# }}}
# {{{ configure_xapian_omega_command()
configure_xapian_omega_command()
{
    #PKG_CONFIG="$PKGCONFIG_BASE/bin/pkg-config" \
    #mac     brew install libmagic
    XAPIAN_CONFIG="$XAPIAN_CORE_BASE/bin/xapian-config" \
    PCRE_CONFIG="$PCRE_BASE/bin/pcre-config" \
    ./configure --prefix=$XAPIAN_OMEGA_BASE \
                --sysconfdir=$XAPIAN_OMEGA_CONFIG_DIR \
                --with-iconv
}
# }}}
# {{{ configure_xapian_bindings_php_command()
configure_xapian_bindings_php_command()
{
    #make 时报错php7/xapian_wrap.cc:1096:27: error: 'xapian_globals' was not declared in this scope
    if `is_new_version "1.4.9" "$XAPIAN_BINDINGS_VERSION"` ; then
        patch -RNs php7/php7/xapian_wrap.cc -i ${curr_dir}/xapian_wrap.diff
        if [ "$?" != "0" ];then
            echo 'patch xapian_wrap.cc faild.' >&2
            return 1
        fi
    fi

    ./configure --prefix=$XAPIAN_BINDINGS_BASE \
                --with-php7 \
                PHP_CONFIG7="$PHP_BASE/bin/php-config" \
                XAPIAN_CONFIG="$XAPIAN_CORE_BASE/bin/xapian-config"
}
# }}}
# {{{ function after_xapian_bindings_php_make_install()
function after_xapian_bindings_php_make_install()
{
    write_extension_info_to_php_ini "xapian.so"
}
# }}}
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

    if [ "$OS_NAME" != "darwin" ];then
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

    # 有readline的时候，报错:
    #$READLINE_BASE/lib/libreadline.so: undefined reference to `tgetnum'
    #$READLINE_BASE/lib/libreadline.so: undefined reference to `tgetent'
    #$READLINE_BASE/lib/libreadline.so: undefined reference to `tgetstr'
    #$READLINE_BASE/lib/libreadline.so: undefined reference to `tgoto'
    #$READLINE_BASE/lib/libreadline.so: undefined reference to `UP'
    #$READLINE_BASE/lib/libreadline.so: undefined reference to `BC'
    #$READLINE_BASE/lib/libreadline.so: undefined reference to `tputs'
    #$READLINE_BASE/lib/libreadline.so: undefined reference to `PC'
    #$READLINE_BASE/lib/libreadline.so: undefined reference to `tgetflag'

    if [ ! -f "./configure" ] ;then
        ./bootstrap
        local flag=$?
        if [ "$flag" != "0" ];then
            return $flag;
        fi
    fi

    #autoreconf -f -i  && \

    #./bootstrap && \
    CFLAGS="$(get_cppflags $LIBPNG_BASE/include $LIBICONV_BASE/include )" \
    LDFLAGS="$(get_ldflags $LIBPNG_BASE/lib $LIBICONV_BASE/lib )" \
    ./configure --prefix=$FONTFORGE_BASE \
                --disable-python-scripting \
                --disable-python-extension \
                --with-libiconv-prefix=$LIBICONV_BASE \
                --without-libreadline \
                --without-x
                # --without-libiconv \
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
                --with-nghttp2=$NGHTTP2_BASE \
                --enable-ipv6 \
                --with-ssl=$OPENSSL_BASE
}
# }}}
# {{{ configure_harfbuzz_command()
configure_harfbuzz_command()
{
    CPPFLAGS="$(get_cppflags ${ICU_BASE}/include ${FREETYPE_BASE}/include)" \
    LDFLAGS="$(get_ldflags ${ICU_BASE}/lib ${FREETYPE_BASE}/lib)" \
    ./configure --prefix=$HARFBUZZ_BASE
}
# }}}
# {{{ configure_python_command()
configure_python_command()
{
    CFLAGS="$(get_cppflags $ZLIB_BASE/include $OPENSSL_BASE/include $READLINE_BASE/include)" \
    CPPFLAGS="$(get_cppflags $ZLIB_BASE/include $OPENSSL_BASE/include $READLINE_BASE/include)" \
    LDFLAGS="$(get_ldflags $ZLIB_BASE/lib $OPENSSL_BASE/lib $READLINE_BASE/lib)" \
    ./configure --prefix=$PYTHON_BASE \
                --enable-optimizations \
                --enable-ipv6 \
                --enable-loadable-sqlite-extensions \
                --with-openssl=$OPENSSL_BASE \

                #--sysconfdir=$BASE_DIR/etc/python
}
# }}}
# {{{ configure_php_command()
configure_php_command()
{
    # mac下 报gmp版本太低,没使用上编译的gmp
    if [ "$OS_NAME" = "darwin" ];then
        if [ "$PHP_VERSION" = "7.1.5" ];then
            sed -i.bak$$ '38311{/^ \{0,\}LDFLAGS=$O_LDFLAGS \{0,\}/d;}' ./configure
            sed -i.bak$$ '37700a\
                LDFLAGS=$O_LDFLAGS' ./configure
        elif [ "$PHP_VERSION" = "7.1.6" ];then
            sed -i.bak$$ '38312{/^ \{0,\}LDFLAGS=$O_LDFLAGS \{0,\}$/d;}' ./configure
            sed -i.bak$$ '37701a\
                LDFLAGS=$O_LDFLAGS' ./configure
        elif [ "$PHP_VERSION" = "7.1.9" ];then
            sed -i.bak$$ '38514{/^ \{0,\}LDFLAGS=$O_LDFLAGS \{0,\}$/d;}' ./configure
            sed -i.bak$$ '37903a\
                LDFLAGS=$O_LDFLAGS' ./configure
        fi
    fi

    #echo $PATH;

    # EXTRA_LIBS="-lresolv" \
    ./configure --prefix=$PHP_BASE \
                --sysconfdir=$PHP_FPM_CONFIG_DIR \
                --with-config-file-path=$PHP_CONFIG_DIR \
                $( [ `echo "$PHP_VERSION 7.2.0"|tr " " "\n"|sort -rV|head -1` = "$PHP_VERSION" ] && echo "" || echo "--runstatedir=${BASE_DIR}/run" ) \
                $(is_installed_apache && echo --with-apxs2=$APACHE_BASE/bin/apxs || echo "") \
                --with-openssl=$OPENSSL_BASE \
                --enable-mysqlnd  \
                --with-zlib-dir=$ZLIB_BASE \
                --with-pdo-mysql=mysqlnd \
                --with-pdo-sqlite=$SQLITE_BASE --without-sqlite3 \
                $( [ `echo "$PHP_VERSION 7.2.0"|tr " " "\n"|sort -rV|head -1` = "$PHP_VERSION" ] && echo "" || echo "--enable-zip --with-zlib-dir=$ZLIB_BASE" ) \
                --enable-soap \
                --with-libxml-dir=$LIBXML2_BASE \
                --with-gettext=$GETTEXT_BASE \
                --with-iconv=$LIBICONV_BASE \
                $( [ `echo "$PHP_VERSION 7.1.99"|tr " " "\n"|sort -rV|head -1` = "$PHP_VERSION" ] && echo "" || echo "--with-mcrypt=$LIBMCRYPT_BASE" ) \
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
                $( has_systemd && echo '--with-fpm-systemd' ) \
                $( [ \"$OS_NAME\" != \"darwin\" ] && echo --with-fpm-acl ) \
                --with-gd=$LIBGD_BASE \
                --with-freetype-dir=$FREETYPE_BASE \
                $( [ `echo "$PHP_VERSION 7.2.1"|tr " " "\n"|sort -rV|head -1` = "$PHP_VERSION" ] && echo "--with-webp-dir=$LIBWEBP_BASE" || echo "") \
                $( [ `echo "$PHP_VERSION 7.1.99"|tr " " "\n"|sort -rV|head -1` = "$PHP_VERSION" ] && echo "" || echo "--enable-gd-native-ttf" ) \
                --with-jpeg-dir=$LIBJPEG_BASE \
                --with-png-dir=$LIBPNG_BASE \
                --with-xpm-dir=$LIBXPM_BASE \
                --with-zlib-dir=$ZLIB_BASE \
                --with-readline=$READLINE_BASE \
                $( [ `echo "$PHP_VERSION 7.1.0"|tr " " "\n"|sort -rV|head -1` = "$PHP_VERSION" ] && echo "--disable-zend-signals" ||echo " ") \
                --enable-opcache

                # --enable-phpdbg \
                # --enable-phpdbg-webhelper \
                # --with-openssl=$OPENSSL_BASE --with-system-ciphers --with-kerberos=$KERBEROS_BASE

                # --with-libzip=$LIBZIP_BASE \

                # --with-fpm-systemd \  # Your system does not support systemd.

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

    if [ "$OS_NAME" != "darwin" ];then
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
    #CPPFLAGS="$( [ \"$OS_NAME\" != \"darwin\" ] && echo '-Wl,--enable-new-dtags,-rpath,\$(LIBRPATH)')" \
    #LDFLAGS="$( [ \"$OS_NAME\" = \"darwin\" ] && echo '-headerpad_max_install_names')" \
    ./configure --prefix=$ICU_BASE
                #--enable-rpath
                #$( [ "$OS_NAME" = "darwin" ] && echo 'LDFLAGS="-headerpad_max_install_names"')

}
# }}}
# {{{ configure_postgresql_command()
configure_postgresql_command()
{
    CFLAGS="$(get_cppflags $ZLIB_BASE/include $OPENSSL_BASE/include $LIBXML2_BASE/include $LIBXSLT_BASE/include $READLINE_BASE/include $GETTEXT_BASE/include)" \
    CPPFLAGS="$(get_cppflags $ZLIB_BASE/include $OPENSSL_BASE/include $LIBXML2_BASE/include $LIBXSLT_BASE/include $READLINE_BASE/include $GETTEXT_BASE/include)" \
    LDFLAGS="$(get_ldflags $ZLIB_BASE/lib $OPENSSL_BASE/lib $LIBXML2_BASE/lib $LIBXSLT_BASE/lib $READLINE_BASE/lib $GETTEXT_BASE/lib)" \
    ./configure --prefix=$POSTGRESQL_BASE \
                --with-libxml \
                --with-libxslt \
                --sysconfdir=$POSTGRESQL_CONFIG_DIR \
                $( [ "$OS_NAME" = "darwin" ] && echo '--with-uuid=e2fs' || echo '--with-ossp-uuid') \
                $( has_systemd && echo "--with-systemd" ) \
                --with-openssl \
                --enable-nls=zh_CN
}
# }}}
# {{{ configure_nginx_command()
configure_nginx_command()
{
    # vim nginx配置文件语法支持
    #cp -r contrib/vim ~/.vim/bundle/nginx

    if [ "$HIDE_NGINX" = "1" ];then
        sed -i.bak.$$ "s/Server: nginx/Server: ${NGINX_CUSTOMIZE_NAME}\/${NGINX_CUSTOMIZE_VERSION}/" ./src/http/ngx_http_header_filter_module.c
        sed -i.bak.$$ "s/<hr><center>nginx<\/center>/<hr><center>${NGINX_CUSTOMIZE_NAME}\/${NGINX_CUSTOMIZE_VERSION}<\/center>/" ./src/http/ngx_http_special_response.c
        #local len=`echo ${NGINX_CUSTOMIZE_NAME_HUFFMAN}|awk -F'\\' '{print NF -1 ; }'`
        local len=${#NGINX_CUSTOMIZE_NAME};
        sed -i.bak.$$ "s/nginx\[5\] = \"$(sed_quote2 '\x84\xaa\x63\x55\xe7' )\"/nginx[${len}] = \"$(sed_quote2 ${NGINX_CUSTOMIZE_NAME_HUFFMAN})\"/" ./src/http/v2/ngx_http_v2_filter_module.c
    fi

    ./configure --prefix=$NGINX_BASE \
                --conf-path=$NGINX_CONFIG_DIR/conf/nginx.conf \
                $( is_new_version $NGINX_VERSION "1.9.5" && echo "--with-http_v2_module" ) \
                $( is_new_version $NGINX_VERSION "1.12.0" || echo "--with-ipv6" ) \
                --with-threads \
                --with-http_mp4_module \
                --with-http_sub_module \
                --with-http_ssl_module \
                --with-http_stub_status_module \
                --with-http_realip_module \
                --with-pcre=../pcre-$PCRE_VERSION \
                --with-zlib=../zlib-$ZLIB_VERSION \
                --with-openssl=../openssl-$OPENSSL_VERSION \
                --with-openssl-opt="enable-tls1_3 enable-weak-ssl-ciphers" \
                --with-http_gunzip_module \
                --build=${project_name%% *} \
                --with-http_addition_module \
                --with-http_random_index_module \
                --with-mail \
                --with-mail_ssl_module \
                --add-dynamic-module=../nginx-upload-progress-module-${NGINX_UPLOAD_PROGRESS_MODULE_VERSION} \
                --add-dynamic-module=../nginx-push-stream-module-${NGINX_PUSH_STREAM_MODULE_VERSION} \
                --with-http_gzip_static_module \
                --with-cc-opt="$(get_cppflags $LIBMAXMINDDB_BASE/include)" \
                --with-ld-opt="$(get_ldflags $LIBMAXMINDDB_BASE/lib)" \
                --add-dynamic-module=../ngx_http_geoip2_module-${NGINX_HTTP_GEOIP2_MODULE_VERSION}

                # 为了支持windows XP IE8
                #--with-openssl-opt="enable-weak-ssl-ciphers" \
                # 用add-module 编译成功后，upload 和push stream模块没作用。不知道是怎么回事
                #下面这个模块报错
                #--add-module=../${NGINX_STICKY_MODULE_FILE_NAME%%.*} \
                #--add-module=../nginx-upload-module-${NGINX_UPLOAD_MODULE_VERSION} \

    local flag="$?"
    if [ "$flag" != "0" ]; then
        return 1;
    fi

    # openssl编译不过去
    [ "$OS_NAME" = "darwin" ] && \
    sed -i.bak 's/config --prefix/Configure darwin64-x86_64-cc --prefix/' ./objs/Makefile || :

    local flag="$?"
    if [ "$flag" != "0" ]; then
        return 1;
    fi

    # openssl编译不过去, 这个不起作用
    #$( [ \"$OS_NAME\" = \"darwin\" ] && echo --with-openssl-opt=\"-darwin64-x86_64-cc\" ) \


                # the HTTP image filter module requires the GD library.
                # --with-http_image_filter_module \
                # --add-module=../nginx-accesskey-2.0.3 \
                # --add-dynamic-module
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
    if [ "$OS_NAME" = "darwin" ];then
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

    if [ "$OS_NAME" = 'darwin' ];then
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
# {{{ configure_patchelf_command()
configure_patchelf_command()
{
    ./bootstrap.sh && ./configure --prefix=$PATCHELF_BASE
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
    if [ "$OS_NAME" != "darwin" ];then
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

    if [ "$OS_NAME" != 'darwin' -a -z "$gcc" ];then
        echo "please update your compiler." >&2
        return 1;
    fi

    sed -i.bak "s/#include \"$(sed_quote poppler/GfxState.h)\"/#include \"$(sed_quote ${POPPLER_BASE}/include/poppler/GfxState.h)\"/" $POPPLER_BASE/include/poppler/splash/SplashBitmap.h

    #指定编译器,因为编译器版本太低，重新编译了编译器

     cmake ./ -DCMAKE_INSTALL_PREFIX=$PDF2HTMLEX_BASE \
              $([ "$OS_NAME" != 'darwin' ] && echo "
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
    CPPFLAGS="$(get_cppflags ${ZLIB_BASE}/include ${LIBPNG_BASE}/include ${FREETYPE_BASE}/include ${FONTCONFIG_BASE}/include ${LIBJPEG_BASE}/include $([ "$OS_NAME" = 'darwin' ] && echo " $LIBX11_BASE/include") )" \
    LDFLAGS="$(get_ldflags ${ZLIB_BASE}/lib ${LIBPNG_BASE}/lib ${FREETYPE_BASE}/lib ${FONTCONFIG_BASE}/lib ${LIBJPEG_BASE}/lib $([ "$OS_NAME" = 'darwin' ] && echo " $LIBX11_BASE/lib") )" \
    ./configure --prefix=$IMAGEMAGICK_BASE \
                $( [ \"$OS_NAME\" != \"darwin\" ] && echo '--enable-opencl' )
                #--without-png \
}
# }}}
# {{{ configure_php_swoole_command()
configure_php_swoole_command()
{
    local kernel_release=$(uname -r);
    kernel_release=${kernel_release%%-*}

    # 4.0.4 编译不上 pcre 和postgresql
    # 编译时如果没有pcre，使用时会有意想不到的结果 $memory_table->count() > 0，但是foreach 结果为空
    CPPFLAGS="$( get_cppflags $OPENSSL_BASE/include \
                              $PCRE_BASE/include \
                              $NGHTTP2_BASE/include \
                              $HIREDIS_BASE/include \
                              )" \
    LDFLAGS="$(get_ldflags $OPENSSL_BASE/lib \
                           $PCRE_BASE/lib \
                           $NGHTTP2_BASE/lib \
                           $HIREDIS_BASE/lib \
                           )" \
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --with-swoole \
                --enable-swoole \
                --enable-swoole-static \
                --enable-sockets \
                --enable-openssl \
                --with-openssl-dir=$OPENSSL_BASE \
                --enable-async-redis \
                --enable-thread \
                --enable-http2 \
                --enable-mysqlnd \
                --enable-timewheel

                # 编译后，swoole.so报错
                #--enable-asan \
                #configure 有问题，编译不上
                #$( is_installed postgresql "$POSTGRESQL_BASE" \
                #&& echo "
                #--enable-coroutine-postgresql \
                #--with-libpq-dir=$POSTGRESQL_BASE \
                #") \

                #-enable-jemalloc \

                # CentOS 7.1  php7.1.4 swoole2.0.7  php -m 报错 Segmentation fault
                #$( [ `echo "$kernel_release 2.6.33" | tr " " "\n"|sort -rV|head -1 ` = "$kernel_release" ] && echo "--enable-hugepage" || echo "" )

               #--enable-picohttpparser
               #--with-phpx-dir=
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
    #sed $( [ "$OS_NAME" = "darwin" ] && echo "-i ''" ||  echo '-i ' ) 's/\([^a-zA-Z0-9_-]\)buffio.h/\1tidybuffio.h/' tidy.c
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
    is_installed rabbitmq $RABBITMQ_BASE
    if [ "$?" = "0" ];then
        return;
    fi

    RABBITMQ_CONFIGURE="
    ./configure --prefix=$RABBITMQ_BASE \
                --with-libiconv-prefix=$LIBICONV_BASE
    "

    compile "rabbitmq" "$RABBITMQ_FILE_NAME" "rabbitmq-$RABBITMQ_VERSION" "$RABBITMQ_BASE" "RABBITMQ_CONFIGURE"
}
# }}}
# {{{ function compile_phantomjs()
function compile_phantomjs()
{
    #这个编译太慢，不编译了
    is_installed phantomjs ${PHANTOMJS_BASE}
    if [ "$?" = "0" ];then
        return;
    fi

    echo_build_start phantomjs

    local phantomjs_dir=${PHANTOMJS_FILE_NAME%.*}
    phantomjs_dir=${phantomjs_dir%.tar}

    mkdir -p ${PHANTOMJS_BASE}/bin && \
      decompress $PHANTOMJS_FILE_NAME && \
      cp ${phantomjs_dir}/bin/phantomjs $PHANTOMJS_BASE/bin/ && \
      rm -rf $phantomjs_dir

    if [ "$?" != "0" ]; then
        echo "安装phantomjs失败" >&2
        #return 1;
        exit 1;
    fi
    [ "$OS_NAME" = "linux" ] && repair_elf_file_rpath ${PHANTOMJS_BASE}/bin/phantomjs
}
# }}}
# {{{ function compile_nodejs()
function compile_nodejs()
{
    #这个编译太慢，不编译了
    is_installed nodejs ${NODEJS_BASE}
    if [ "$?" = "0" ];then
        return;
    fi

    echo_build_start nodejs

    local nodejs_dir=${NODEJS_FILE_NAME%.*}
    nodejs_dir=${nodejs_dir%.tar}

    mkdir -p ${NODEJS_BASE} && \
      rm -rf  ${NODEJS_BASE}/* && \
      decompress $NODEJS_FILE_NAME && \
      cp -r ${nodejs_dir}/* $NODEJS_BASE/ && \
      rm -rf $nodejs_dir

    if [ "$?" != "0" ]; then
        echo "安装nodejs失败" >&2
        #return 1;
        exit 1;
    fi
    deal_path "$NODEJS_BASE"
    #ping_usable registry.npm.org 100 || npm config set registry http://registry.npm.taobao.org
}
# }}}
# {{{ function compile_calibre()
function compile_calibre()
{
    is_installed calibre ${CALIBRE_BASE}
    if [ "$?" = "0" ];then
        return;
    fi

    echo_build_start calibre

    mkdir -p ${CALIBRE_BASE} && \
      rm -rf  ${CALIBRE_BASE}/* && \
      decompress $CALIBRE_FILE_NAME $CALIBRE_BASE

    if [ "$?" != "0" ]; then
        echo "安装calibre失败" >&2
        #return 1;
        exit 1;
    fi

    if [ "$OS_NAME" = "darwin" ];then
        if [ ! -d "/Volumes/calibre-${CALIBRE_VERSION}/calibre.app/Contents/MacOS" ];then
            echo "安装calibre失败. 没有找到解压后的目录" >&2
            exit 1;
        fi
        cp -r /Volumes/calibre-${CALIBRE_VERSION}/calibre.app/Contents/MacOS/* $CALIBRE_BASE/
        hdiutil detach /Volumes/calibre-${CALIBRE_VERSION}
    fi

    [ "$OS_NAME" != "linux" ] || repair_dir_elf_rpath $CALIBRE_BASE
}
# }}}
# {{{ function compile_gitbook_cli()
function compile_gitbook_cli()
{
    compile_nodejs

    is_installed gitbook_cli ${GITBOOK_CLI_BASE}
    if [ "$?" = "0" ];then
        return;
    fi

    #compile_gitbook

    echo_build_start gitbook-cli

    local gitbook_cli_dir=${GITBOOK_CLI_FILE_NAME%.*}
    gitbook_cli_dir=${gitbook_cli_dir%.tar}

    #mkdir -p ${GITBOOK_CLI_BASE} && \
    #  rm -rf  ${GITBOOK_CLI_BASE}/* && \
    #  decompress $GITBOOK_CLI_FILE_NAME && \
    #  cp -r ${gitbook_cli_dir}/* $GITBOOK_CLI_BASE/ && \
    #  rm -rf $gitbook_cli_dir && \
    #  $(cd $NODEJS_BASE/bin && ln -s ../lib/node_modules/gitbook-cli/bin/gitbook.js gitbook)

    npm install gitbook-cli@${GITBOOK_CLI_VERSION} -g


    if [ "$?" != "0" ]; then
        echo "安装gitbook-cli失败" >&2
        #return 1;
        exit 1;
    fi
    compile_gitbook_pdf
}
# }}}
# {{{ function compile_gitbook()
function compile_gitbook()
{
    compile_nodejs

    is_installed gitbook ${GITBOOK_BASE}
    if [ "$?" = "0" ];then
        return;
    fi

    echo_build_start gitbook

    local gitbook_dir=${GITBOOK_FILE_NAME%.*}
    gitbook_dir=${gitbook_dir%.tar}

    #mkdir -p ${GITBOOK_BASE} && \
    #  rm -rf  ${GITBOOK_BASE}/* && \
    #  decompress $GITBOOK_FILE_NAME && \
    #  cp -r ${gitbook_dir}/* $GITBOOK_BASE/ && \
    #  rm -rf $gitbook_dir && \
    ##  $(cd $NODEJS_BASE/bin && ln -s ../lib/node_modules/gitbook/bin/gitbook.js gitbook)

    npm install gitbook@${GITBOOK_VERSION} -g

    if [ "$?" != "0" ]; then
        echo "安装gitbook失败" >&2
        #return 1;
        exit 1;
    fi
}
# }}}
# {{{ function compile_gitbook_pdf()
function compile_gitbook_pdf()
{
    compile_nodejs
    compile_phantomjs
    compile_gitbook_cli

    is_installed gitbook_pdf ${GITBOOK_BASE}
    if [ "$?" = "0" ];then
        return;
    fi


    echo_build_start gitbook-pdf

    #PHANTOMJS_CDNURL=http://npm.taobao.org/dist/phantomjs npm install phantomjs
    #PHANTOMJS_CDNURL=http://cnpmjs.org/downloads npm install phantomjs
    #npm config set registry http://registry.npm.taobao.org -g

    #export PHANTOMJS_CDNURL="http://npm.taobao.org/dist/phantomjs"
    #ping_usable cdn.bitbucket.org || \
    #npm config set phantomjs_cdnurl=http://npm.taobao.org/dist/phantomjs && \
    #npm config set registry http://registry.npm.taobao.org

    #npm install phantomjs -g

    npm install gitbook-pdf -g


    if [ "$?" != "0" ]; then
        echo "安装gitbook-pdf失败" >&2
        #return 1;
        exit 1;
    fi
}
# }}}
# {{{ function compile_php_extension_rabbitmq()
function compile_php_extension_rabbitmq()
{
    compile_rabbitmq

    echo "compile_php_extension_rabbitmq 未完成" >&2
    return 1;
    is_installed_php_extension rabbitmq $RABBITMQ_VERSION
    if [ "$?" = "0" ];then
        return;
    fi

    PHP_EXTENSION_rabbitmq_CONFIGURE="
    ./configure --with-php-config=$PHP_BASE/bin/php-config \
                --with-librabbitmq-dir=$RABBITMQ_C_BASE
    "

    compile "php_extension_rabbitmq" "$RABBITMQ_FILE_NAME" "php-rabbitmq-$RABBITMQ_VERSION" "rabbitmq.so" "PHP_EXTENSION_RABBITMQ_CONFIGURE"

    /bin/rm -rf package.xml

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

    is_echo_latest=0

#    check_version zend
#    check_version jquery
#    check_version famous
#    check_version famous_framework
#    check_version famous_angular
#check_version swfupload
#    exit;
    local array=(
            python
            xunsearch_sdk_php
            xunsearch
            scws
            fribidi
            libwebp
            xapian_core
            xapian_omega
            xapian_bindings
            browscap
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
            memcached
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
            gearman
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
            json_c
            libfastjson
            nginx
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
            pecl_sphinx
            openjpeg
            pdf2htmlEX

            pecl_grpc
            pecl_protobuf
            pecl_pthreads
            pecl_zip
            pecl_solr
            pecl_mailparse
            pecl_amqp
            pecl_http
            pecl_propro
            pecl_raphf
            pecl_apcu
            pecl_apcu_bc
            pecl_libevent
            pecl_event
            pecl_xdebug
            pecl_dio
            pecl_memcached
            pecl_qrencode
            pecl_mongodb
            pecl_zmq
            pecl_redis
            pecl_imagick
            pecl_phalcon
            pecl_yaf
            pecl_libsodium

            smarty
            jquery
            jquery3
            d3
            chartjs
            htmlpurifier
            rabbitmq
            libmaxminddb
            maxmind_db_reader_php
            web_service_common_php
            geoip2_php
            geoipupdate
            electron
            phantomjs
            laravel
            laravel_framework

            nginx_upload_module
            nginx_upload_progress_module
            nginx_push_stream_module
            nginx_http_geoip2_module
            nginx_sticky_module

            );
    multi_process check_version check_version 15 "${array[@]}"
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

    local versions=`curl -Lk https://www.openssl.org/source/ 2>/dev/null|sed -n "s/^.\{1,\}>openssl-\($tmp[0-9a-zA-Z.]\{2,\}\).tar.gz.\{1,\}/\1/p"|sort -rV`
    local new_version=`echo "$versions"|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测openssl新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $OPENSSL_VERSION $new_version
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
        echo -e "openssl version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "openssl current version: \033[0;33m${OPENSSL_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_redis_version()
function check_redis_version()
{
    local versions=`curl -Lk https://redis.io/ 2>/dev/null|sed -n 's/^.\{1,\}redis-\([0-9a-zA-Z.]\{2,\}\).tar.gz.\{1,\}/\1/p'|sort -rV`
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
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
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
    local new_version=`curl -Lk https://fossies.org/linux/misc/ 2>/dev/null|sed -n 's/^.\{1,\}>icu4c-\([0-9a-zA-Z._]\{2,\}\)-src.tgz<.\{1,\}/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测icu新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $ICU_VERSION ${new_version//_/.}
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
        echo -e "icu version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "icu current version: \033[0;33m${ICU_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_curl_version()
function check_curl_version()
{
    local new_version=`curl -Lk https://curl.haxx.se/download/ 2>/dev/null|sed -n 's/^.\{1,\}>curl-\([0-9a-zA-Z._]\{2,\}\).tar.gz<.\{1,\}/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测curl新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $CURL_VERSION ${new_version//_/.}
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
        echo -e "curl version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "curl current version: \033[0;33m${CURL_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_zlib_version()
function check_zlib_version()
{
    local new_version=`curl -Lk http://zlib.net 2>/dev/null|sed -n 's/^.\{0,\}"zlib-\([0-9a-zA-Z._]\{2,\}\).tar.gz".\{0,\}/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测zlib新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $ZLIB_VERSION ${new_version//_/.}
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
        echo -e "zlib version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "zlib current version: \033[0;33m${ZLIB_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_libunwind_version()
function check_libunwind_version()
{
    local new_version=`curl -Lk http://download.savannah.gnu.org/releases/libunwind/ 2>/dev/null|sed -n 's/^.\{0,\}"libunwind-\([0-9a-zA-Z._]\{2,\}\).tar.gz".\{0,\}/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测libunwind新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $LIBUNWIND_VERSION ${new_version//_/.}
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
        echo -e "libunwind version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "libunwind current version: \033[0;33m${LIBUNWIND_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_freetype_version()
function check_freetype_version()
{
    local new_version=`curl -Lk https://www.freetype.org/ 2>/dev/null|sed -n 's/^.\{0,\}<h4>FreeType \([0-9.]\{3,\}\)<\/h4>.\{0,\}$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测freetype新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $FREETYPE_VERSION ${new_version//_/.}
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
        echo -e "freetype version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "freetype current version: \033[0;33m${FREETYPE_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_browscap_version()
function check_browscap_version()
{
    local new_version=`curl -Lk https://browscap.org/version-number 2>/dev/null`
    if [ -z "$new_version" ];then
        echo -e "探测browscap.ini新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $BROWSCAP_INI_VERSION ${new_version//_/.}
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
        echo -e "browscap.ini version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "browscap.ini current version: \033[0;33m${BROWSCAP_INI_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_harfbuzz_version()
function check_harfbuzz_version()
{
    check_ftp_version harfbuzz ${HARFBUZZ_VERSION} https://www.freedesktop.org/software/harfbuzz/release/ 's/^.\{1,\}>harfbuzz-\([0-9.]\{1,\}\)\.tar\.bz2<.\{0,\}$/\1/p'
}
# }}}
# {{{ function check_xapian_core_version()
function check_xapian_core_version()
{
    check_ftp_version xapian-core ${XAPIAN_CORE_VERSION} https://xapian.org/download 's/^.\{1,\}xapian-core-\([0-9.]\{1,\}\)\.tar\..\{0,\}$/\1/p'
}
# }}}
# {{{ function check_xapian_omega_version()
function check_xapian_omega_version()
{
    check_ftp_version xapian-omega ${XAPIAN_OMEGA_VERSION} https://xapian.org/download 's/^.\{1,\}xapian-omega-\([0-9.]\{1,\}\)\.tar\..\{0,\}$/\1/p'
}
# }}}
# {{{ function check_xapian_bindings_version()
function check_xapian_bindings_version()
{
    check_ftp_version xapian-bindings ${XAPIAN_BINDINGS_VERSION} https://xapian.org/download 's/^.\{1,\}xapian-bindings-\([0-9.]\{1,\}\)\.tar\..\{0,\}$/\1/p'
}
# }}}
# {{{ function check_libzip_version()
function check_libzip_version()
{
    check_ftp_version libzip ${LIBZIP_VERSION} https://nih.at/libzip/ 's/^.\{0,\}libzip-\([0-9a-zA-Z._]\{2,\}\).tar.gz.\{0,\}$/\1/p'
}
# }}}
# {{{ function check_python_version()
function check_python_version()
{
    local tmp=""
    if [ "$#" = "0" ]; then
        check_python_version 1
    fi

    #只查找当前小版本
    if [ "$1" = "1" ]; then
        local tmp=${PYTHON_VERSION%.*}
    fi

    local versions=`curl -Lk https://www.python.org/downloads/ 2>/dev/null | sed -n "s/^.\{1,\}>Python \{1,\}\(${tmp}[0-9.]\{2,\}\)<.\{1,\}$/\1/p"|sort -rV`
    local new_version=`echo "$versions"|head -1`;
    if [ -z "$new_version" ];then
        echo -e "探测python新版本\033[0;31m失败\033[0m" >&2
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

    is_new_version $PYTHON_VERSION $new_version
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
        echo -e "python version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "python current version: \033[0;33m${PYTHON_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
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
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
        echo -e "php version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "php current version: \033[0;33m${PHP_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_gmp_version()
function check_gmp_version()
{
    local new_version=`curl -Lk https://gmplib.org/ 2>/dev/null|sed -n 's/^.\{1,\}gmp-\([0-9.]\{1,\}\)\.tar\.xz.\{1,\}$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测gmp新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $GMP_VERSION $new_version
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
        echo -e "gmp version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "gmp current version: \033[0;33m${GMP_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_mysql_version()
function check_mysql_version()
{
    local new_version=`curl -Lk https://dev.mysql.com/downloads/mysql/ 2>/dev/null |sed -n 's/<h1> \{0,\}MySQL \{1,\}Community \{1,\}Server \{0,\}\(.\{1,\}\) \{0,\}<\/h1>/\1/p'|sort -rV|head -1`;
    new_version=${new_version// /}
    if [ -z "$new_version" ];then
        echo -e "探测mysql新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $MYSQL_VERSION $new_version
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
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
    local new_version=`curl -Lk http://nginx.org/en/download.html 2>/dev/null |sed -n 's/^.\{1,\}Stable version\(.\{1,\}\)Legacy versions.\{1,\}$/\1/p'|sed -n 's/^.\{1,\}nginx-\([0-9.]\{1,\}\)\.tar\.gz".\{1,\}$/\1/gp'|sort -rV|head -1`;
    new_version=${new_version// /}
    if [ -z "$new_version" ];then
        echo -e "探测nginx新版本\033[0;31m失败\033[0m" >&2
            return 1;
    fi

    is_new_version $NGINX_VERSION $new_version
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
        echo -e "nginx version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "nginx current version: \033[0;33m${NGINX_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"

}
# }}}
# {{{ function check_nodejs_version()
function check_nodejs_version()
{
    #https://nodejs.org/en/download/
    check_ftp_version nodejs ${NODEJS_VERSION} https://nodejs.org/en/download/ 's/^.\{1,\}[> ]node-v\([0-9.]\{1,\}\)\.tar\.gz[< ]*.\{0,\}$/\1/p'
    check_ftp_version nodejs ${NODEJS_VERSION} https://nodejs.org/en/download/current/ 's/^.\{1,\}[> ]node-v\([0-9.]\{1,\}\)\.tar\.gz[< ]*.\{0,\}$/\1/p'
}
# }}}
# {{{ function check_jquery_version()
function check_jquery_version()
{
    check_ftp_version jquery ${JQUERY_VERSION%%.min} https://code.jquery.com/jquery/ 's/^.\{1,\}jquery-\(1.[0-9.]\{1,\}\)\.js.\{1,\}$/\1/p'
    #check_ftp_version jquery ${JQUERY_VERSION%%.min} https://code.jquery.com/jquery/ 's/^.\{1,\}jquery-\([0-9.]\{1,\}\)\.js.\{1,\}$/\1/p'
}
# }}}
# {{{ function check_jquery3_version()
function check_jquery3_version()
{
    check_ftp_version jquery3 ${JQUERY3_VERSION%%.min} https://code.jquery.com/jquery/ 's/^.\{1,\}jquery-\([0-9.]\{1,\}\)\.js.\{1,\}$/\1/p'
}
# }}}
# {{{ function check_d3_version()
function check_d3_version()
{
    check_github_soft_version d3 ${D3_VERSION} https://github.com/d3/d3/releases
}
# }}}
# {{{ function check_chartjs_version()
function check_chartjs_version()
{
    check_github_soft_version Chart.js ${CHARTJS_VERSION} https://github.com/chartjs/Chart.js/releases
}
# }}}
# {{{ function check_calibre_version()
function check_calibre_version()
{
    check_github_soft_version calibre ${CALIBRE_VERSION} https://github.com/kovidgoyal/calibre/releases
}
# }}}
# {{{ function check_gitbook_version()
function check_gitbook_version()
{
    check_github_soft_version gitbook $GITBOOK_VERSION "https://github.com/GitbookIO/gitbook/releases"
}
# }}}
# {{{ function check_gitbook_cli_version()
function check_gitbook_cli_version()
{
    check_github_soft_version gitbook-cli $GITBOOK_CLI_VERSION "https://github.com/GitbookIO/gitbook-cli/releases"
}
# }}}
# {{{ function check_nginx_upload_progress_module_version()
function check_nginx_upload_progress_module_version()
{
    check_github_soft_version nginx-upload-progress-module $NGINX_UPLOAD_PROGRESS_MODULE_VERSION "https://github.com/masterzen/nginx-upload-progress-module/releases"
}
# }}}
# {{{ function check_nginx_upload_module_version()
function check_nginx_upload_module_version()
{
    check_github_soft_version nginx-upload-module $NGINX_UPLOAD_MODULE_VERSION "https://github.com/vkholodkov/nginx-upload-module/releases"
}
# }}}
# {{{ function check_nginx_push_stream_module_version()
function check_nginx_push_stream_module_version()
{
    check_github_soft_version nginx-push-stream-module $NGINX_PUSH_STREAM_MODULE_VERSION "https://github.com/wandenberg/nginx-push-stream-module/releases"
}
# }}}
# {{{ function check_nginx_http_geoip2_module_version()
function check_nginx_http_geoip2_module_version()
{
    check_github_soft_version ngx_http_geoip2_module $NGINX_HTTP_GEOIP2_MODULE_VERSION "https://github.com/leev/ngx_http_geoip2_module/releases"
}
# }}}
# {{{ function check_nginx_sticky_module_version()
function check_nginx_sticky_module_version()
{
    check_ftp_version nginx-sticky-module ${NGINX_STICKY_MODULE_VERSION} "https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng/downloads/?tab=tags" 's/^.\{1,\}="[^"]\{1,\}\/get\/v\([0-9.]\{1,\}\)\.tar\.bz2">.\{0,\}$/\1/p'
}
# }}}
# {{{ function check_json_c_version()
function check_json_c_version()
{
    check_github_soft_version json-c $JSON_VERSION "https://github.com/json-c/json-c/releases" "json-c-\([0-9.]\{1,\}\)-[0-9.]\{1,\}.tar.gz" 1
}
# }}}
# {{{ function check_nghttp2_version()
function check_nghttp2_version()
{
    check_github_soft_version nghttp2 $NGHTTP2_VERSION "https://github.com/nghttp2/nghttp2/releases"
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
    local versions=`curl http://www.imagemagick.org/download/releases/ 2>/dev/null|sed -n 's/^.\{1,\} href="ImageMagick-\([0-9.-]\{1,\}\).tar.[a-z0-9A-Z]\{1,\}">.\{1,\}$/\1/p'|sort -rV`
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
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
        echo -e "imagemagick version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "imagemagick current version: \033[0;33m${IMAGEMAGICK_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_pkgconfig_version()
function check_pkgconfig_version()
{
    local new_version=`curl -Lk https://pkg-config.freedesktop.org/releases/ 2>/dev/null |sed -n 's/^.\{1,\} href="pkg-config-\([0-9.]\{1,\}\).tar.gz">.\{1,\}$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测pkgconfig新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $PKGCONFIG_VERSION $new_version
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
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
# {{{ function check_dehydrated_version()
function check_dehydrated_version()
{
    check_github_soft_version dehydrated $DEHYDRATED_VERSION "https://github.com/lukas2511/dehydrated/releases"
}
# }}}
# {{{ function check_nasm_version()
function check_nasm_version()
{
    check_ftp_version nasm $NASM_VERSION "https://www.nasm.us/pub/nasm/releasebuilds/" 's/^.\{1,\}[>]\([0-9.]\{1,\}\)\/[<]*.\{0,\}$/\1/p'
    return

    local new_version=`curl -Lk http://www.nasm.us/ 2>/dev/null |sed -n '/The latest stable version of NASM is/{n;s/^.\{1,\}>\([0-9].\{1,\}\)<.\{1,\}$/\1/p;}'`;
    new_version=${new_version// /}
    if [ -z "$new_version" ];then
        echo -e "探测nasm新版本\033[0;31m失败\033[0m" >&2
            return 1;
    fi

    is_new_version $NASM_VERSION $new_version
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
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
# {{{ function check_htmlpurifier_version()
function check_htmlpurifier_version()
{
    check_github_soft_version htmlpurifier $HTMLPURIFIER_VERSION "https://github.com/ezyang/htmlpurifier/releases"
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
    #check_github_soft_version phantomjs $PHANTOMJS_VERSION "https://github.com/ariya/phantomjs/releases"
    check_ftp_version phantomjs $PHANTOMJS_VERSION "https://bitbucket.org/ariya/phantomjs/downloads/" 's/^.\{1,\}[> ]phantomjs-\([0-9.]\{1,\}\)-windows\{1,\}\.zip[< ]*.\{0,\}$/\1/p'
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
# {{{ function check_pecl_zip_version()
function check_pecl_zip_version()
{
    check_php_pecl_version zip $ZIP_VERSION
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
    #if [ `echo "${PHP_VERSION}" "7.1.99"|tr " " "\n"|sort -rV|head -1` != "7.1.99" ]; then
        #return;
    #fi
    if is_new_version "7.1.99" $PHP_VERSION ;then
        check_github_soft_version libsodium-php $PHP_LIBSODIUM_VERSION "https://github.com/jedisct1/libsodium-php/releases" "\(1\.[0-9.]\{1,\}\).tar.gz" 1
    else
        check_php_pecl_version libsodium $PHP_LIBSODIUM_VERSION
    fi
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
    check_github_soft_version qrencode $PHP_QRENCODE_VERSION "https://github.com/chg365/qrencode/releases"
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
# {{{ function check_pecl_protobuf_version()
function check_pecl_protobuf_version()
{
    check_php_pecl_version protobuf $PHP_PROTOBUF_VERSION
}
# }}}
# {{{ function check_pecl_grpc_version()
function check_pecl_grpc_version()
{
    check_php_pecl_version grpc $PHP_GRPC_VERSION
}
# }}}
# {{{ function check_libevent_version()
function check_libevent_version()
{
    check_github_soft_version libevent $LIBEVENT_VERSION "https://github.com/libevent/libevent/releases" "release-\([0-9.]\{5,\}\)\(-stable\)\{0,1\}\.tar\.gz" 1
}
# }}}
# {{{ function check_patchelf_version()
function check_patchelf_version()
{
    check_github_soft_version patchelf $PATCHELF_VERSION "https://github.com/NixOS/patchelf/releases"
}
# }}}
# {{{ function check_tesseract_version()
function check_tesseract_version()
{
    check_github_soft_version tesseract $TESSERACT_VERSION "https://github.com/tesseract-ocr/tesseract/releases"
}
# }}}
# {{{ function check_rsyslog_version()
function check_rsyslog_version()
{
    check_github_soft_version rsyslog $RSYSLOG_VERSION "https://github.com/rsyslog/rsyslog/releases" "v\([0-9.]\{5,\}\)\(-stable\)\{0,1\}\.tar\.gz" 1
}
# }}}
# {{{ function check_logrotate_version()
function check_logrotate_version()
{
    check_github_soft_version logrotate $LOGROTATE_VERSION "https://github.com/logrotate/logrotate/releases"
}
# }}}
# {{{ function check_libuuid_version()
function check_libuuid_version()
{
    check_sourceforge_soft_version libuuid ${LIBUUID_VERSION//_/.} 's/^.\{0,\}<tr title="libuuid-\([0-9.]\{1,\}\).tar.gz" class="file \{0,\}[^"]\{1,\}"> \{0,\}$/\1/p' "0"
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
    check_http_version "libgcrypt" ${LIBGCRYPT_VERSION} https://gnupg.org/ftp/gcrypt/libgcrypt/
}
# }}}
# {{{ function check_libgpg_error_version()
function check_libgpg_error_version()
{
    check_http_version "libgpg-error" ${LIBGPG_ERROR_VERSION} https://gnupg.org/ftp/gcrypt/libgpg-error/
}
# }}}
# {{{ function check_readline_version()
function check_readline_version()
{
    check_ftp_gnu_org_version readline $READLINE_VERSION
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
    local new_version=`curl -Lk https://developer.gnome.org/glib/ 2>/dev/null |sed -n 's/^.\{1,\}>\([0-9._-]\{1,\}\)<\/a><\/li>.\{0,\}$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测glib新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $GLIB_VERSION $new_version
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
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
    local tmp_str=`echo ${LIBPNG_VERSION%.*}|tr -d .`;
    local tmp_str2=`check_sourceforge_soft_version libpng $tmp_str 's/^ \{0,\}<tr \{1,\}title="libpng\([0-9]\{1,\}\)" \{1,\}class=" \{0,\}folder \{0,\}" \{0,\}> \{0,\}$/\1/p' 0`
    if echo "$tmp_str2"|grep -q 'new version'; then
        tmp_str2=$(echo ${tmp_str2##* }|sed -n "s/^$(echo -e "\033\[0;35m")\([0-9]\{1,\}\)$(echo -e "\033\[0m")\$/\1/p")
        check_sourceforge_soft_version libpng ${LIBPNG_VERSION} 's/^.\{0,\}<tr title="\([0-9.a-zA-Z]\{1,\}\)" class="folder \{0,\}"> \{0,\}$/\1/p' libpng${tmp_str2}
    fi

    check_sourceforge_soft_version libpng ${LIBPNG_VERSION} 's/^.\{0,\}<tr title="\([0-9.]\{1,\}\)" class="folder \{0,\}"> \{0,\}$/\1/p' libpng${tmp_str}
}
# }}}
# {{{ function check_kerberos_version()
function check_kerberos_version()
{
    local new_version=`curl -Lk http://web.mit.edu/kerberos/dist/ 2>/dev/null |sed -n 's/.\{1,\}>krb5-\([0-9.-]\{1,\}\).tar.gz<.\{1,\}$/\1/p'|tr - .|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测kerberos新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $KERBEROS_VERSION $new_version
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
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
    local new_version=`curl -Lk https://www.sqlite.org/download.html 2>/dev/null |sed -n 's/^.\{1,\}\/sqlite-autoconf-\([0-9.]\{1,\}\).tar.gz.\{1,\}$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测sqlite新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $SQLITE_VERSION $new_version
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
        echo -e "sqlite version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "sqlite current version: \033[0;33m${SQLITE_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_imap_version()
function check_imap_version()
{
    local new_version=`curl -Lk https://www.mirrorservice.org/sites/ftp.cac.washington.edu/imap/ 2>/dev/null |sed -n 's/^.\{1,\}>imap-\([0-9a-zA-Z.-]\{1,\}\).tar.gz<.\{1,\}$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测imap新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $IMAP_VERSION $new_version
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
        echo -e "imap version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "imap current version: \033[0;33m${IMAP_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_libmemcached_version()
function check_libmemcached_version()
{
    local new_version=`curl -Lk "https://launchpad.net/libmemcached/+download" 2>/dev/null |sed -n 's/^.*>libmemcached-\([0-9.-]\{1,\}\).tar.gz<.*$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测libmemcached新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $LIBMEMCACHED_VERSION $new_version
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
        echo -e "libmemcached version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "libmemcached current version: \033[0;33m${LIBMEMCACHED_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_qrencode_version()
function check_qrencode_version()
{
    local new_version=`curl -Lk https://fukuchi.org/works/qrencode/ 2>/dev/null |sed -n 's/^.*>qrencode-\([0-9.-]\{1,\}\).tar.gz<.*$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测qrencode新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $QRENCODE_VERSION $new_version
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
        echo -e "qrencode version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "qrencode current version: \033[0;33m${QRENCODE_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_jpeg_version()
function check_jpeg_version()
{
    local new_version=`curl -Lk http://www.ijg.org/files/ 2>/dev/null |sed -n 's/^.*>jpegsrc\.v\([0-9a-zA-Z.]\{1,\}\).tar.gz<.*$/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测jpeg新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $JPEG_VERSION $new_version
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
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
# {{{ function check_libwebp_version()
function check_libwebp_version()
{
    check_github_soft_version libwebp $LIBWEBP_VERSION "https://github.com/webmproject/libwebp/releases"
}
# }}}
# {{{ function check_fribidi_version()
function check_fribidi_version()
{
    check_github_soft_version fribidi $FRIBIDI_VERSION "https://github.com/fribidi/fribidi/releases"
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
    #check_sourceforge_soft_version boost ${BOOST_VERSION//_/.} 's/^.\{0,\}<tr title="\([0-9.]\{1,\}\)" class="folder \{0,\}"> \{0,\}$/\1/p'
    local new_version=`curl -Lk http://www.boost.org/ 2>/dev/null |sed -n 's/^.\{1,\}Version \([0-9._-]\{1,\}\).\{1,\}>Download<.\{1,\}/\1/p'|sort -rV|head -1`
    if [ -z "$new_version" ];then
        echo -e "探测boost新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $BOOST_VERSION $new_version
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
        echo -e "boost version is \033[0;32mthe latest.\033[0m"
        return 0;
    fi

    echo -e "boost current version: \033[0;33m${BOOST_VERSION}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_libmcrypt_version()
function check_libmcrypt_version()
{
    check_sourceforge_soft_version mcrypt ${LIBMCRYPT_VERSION//_/.} 's/^.\{0,\}<tr title="\([0-9.]\{1,\}\)" class="folder \{0,\}"> \{0,\}$/\1/p' Libmcrypt
}
# }}}
# {{{ function check_libwbxml_version()
function check_libwbxml_version()
{
    check_sourceforge_soft_version libwbxml ${LIBWBXML_VERSION//_/.} 's/^.\{0,\}<tr title="\([0-9.]\{1,\}\)" class="folder \{0,\}"> \{0,\}$/\1/p'
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
    check_http_version libXpm ${LIBXPM_VERSION} https://www.x.org/releases/individual/lib/
}
# }}}
# {{{ function check_libXext_version()
function check_libXext_version()
{
    check_http_version libXext ${LIBXEXT_VERSION} https://www.x.org/releases/individual/lib/
}
# }}}
# {{{ function check_kbproto_version()
function check_kbproto_version()
{
    check_http_version kbproto ${KBPROTO_VERSION} https://www.x.org/archive/individual/proto/
}
# }}}
# {{{ function check_inputproto_version()
function check_inputproto_version()
{
    check_http_version inputproto ${INPUTPROTO_VERSION} https://www.x.org/archive/individual/proto/
}
# }}}
# {{{ function check_xextproto_version()
function check_xextproto_version()
{
    check_http_version xextproto ${XEXTPROTO_VERSION} https://www.x.org/archive/individual/proto/
}
# }}}
# {{{ function check_xproto_version()
function check_xproto_version()
{
    check_http_version xproto ${XPROTO_VERSION} https://www.x.org/archive/individual/proto/
}
# }}}
# {{{ function check_xtrans_version()
function check_xtrans_version()
{
    check_http_version xtrans ${XTRANS_VERSION} https://www.x.org/archive/individual/lib/
}
# }}}
# {{{ function check_libXau_version()
function check_libXau_version()
{
    check_http_version libXau ${LIBXAU_VERSION} https://www.x.org/archive/individual/lib/
}
# }}}
# {{{ function check_libX11_version()
function check_libX11_version()
{
    check_http_version libX11 ${LIBX11_VERSION} https://www.x.org/archive/individual/lib/
}
# }}}
# {{{ function check_libpthread_stubs_version()
function check_libpthread_stubs_version()
{
    check_http_version libpthread-stubs ${LIBPTHREAD_STUBS_VERSION} https://www.x.org/archive/individual/xcb/
}
# }}}
# {{{ function check_libxcb_version()
function check_libxcb_version()
{
    check_http_version libxcb ${LIBXCB_VERSION} https://www.x.org/archive/individual/xcb/
}
# }}}
# {{{ function check_xcb_proto_version()
function check_xcb_proto_version()
{
    check_http_version xcb-proto ${XCB_PROTO_VERSION} https://www.x.org/archive/individual/xcb/
}
# }}}
# {{{ function check_macros_version()
function check_macros_version()
{
    check_http_version util-macros ${MACROS_VERSION} https://www.x.org/archive/individual/util/
}
# }}}
# {{{ function check_xf86bigfontproto_version()
function check_xf86bigfontproto_version()
{
    check_http_version xf86bigfontproto ${XF86BIGFONTPROTO_VERSION} https://www.x.org/archive/individual/proto/
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
    check_github_soft_version memcached $MEMCACHED_VERSION "https://github.com/memcached/memcached/releases"
    #check_ftp_version memcached ${MEMCACHED_VERSION} http://memcached.org/files/
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
# {{{ function check_pgbouncer_version()
function check_pgbouncer_version()
{
    check_ftp_version pgbouncer ${PGBOUNCER_VERSION} https://pgbouncer.github.io/
}
# }}}
# {{{ function check_scws_version()
function check_scws_version()
{
    check_github_soft_version scws $SCWS_VERSION "https://github.com/hightman/scws/releases"
}
# }}}
# {{{ function check_xunsearch_version()
function check_xunsearch_version()
{
    check_github_soft_version xunsearch $XUNSEARCH_VERSION "https://github.com/hightman/xunsearch/releases"
}
# }}}
# {{{ function check_xunsearch_sdk_php_version()
function check_xunsearch_sdk_php_version()
{
    check_github_soft_version xs-sdk-php $XUNSEARCH_SDK_VERSION "https://github.com/hightman/xs-sdk-php/releases"
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

    local versions=`curl -Lk "${url}" 2>/dev/null|sed -n "$pattern"|sort -urV`
    local new_version=`echo "$versions"|head -1`;

    if [ -z "$new_version" ];then
        echo -e "探测${soft}新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    echo "$new_version" |grep -iq 'RC'
    if [ "$?" = "0" ]; then
        local tmp_version1=`echo "$versions"|grep -iv 'RC' |head -1`;
        local tmp_version2=`echo "$new_version"|sed -n 's/^\([0-9._-]\{1,\}\)\([Rr][Cc]\).\{1,\}$/\1/p'`;
        if [ "$tmp_version1" != "" ] ;then
            if is_new_version $current_version $tmp_version1; then
                new_version = $tmp_version1;
            fi
            if [ "$tmp_version1" = "$tmp_version2" ];then
                new_version=$tmp_version2;
            fi
        fi
    fi

    #${new_version//_/.}
    is_new_version $current_version $new_version
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
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

    local versions=`curl -Lk $url 2>/dev/null |sed -n "$pattern" |sort -rV`
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
                [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
                echo -e "${soft} version is \033[0;32mthe latest.\033[0m"
                return;
            else
                echo -e "${soft} current version: \033[0;33m${current_version}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
                return;
            fi
        elif [ "$soft" = "php-memcached" ];then
            if [ "$new_version" = "2.2.0" ];then
                [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
                echo -e "${soft} version is \033[0;32mthe latest.\033[0m"
                return;
            else
                echo -e "${soft} current version: \033[0;33m${current_version}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
                return;
            fi
        elif [ "$soft" = "php-zmq" ];then
            if [ "$new_version" = "1.1.2" ];then
                [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
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
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
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

    local versions=`curl -Lk https://pecl.php.net/package/${ext} 2>/dev/null|sed -n "s/^.\{1,\} href=\"\/get\/${ext}-\([0-9._]\{1,\}\(\(RC\)\{0,1\}[0-9]\{1,\}\)\{0,1\}\).tgz\"[^>]\{0,\}>.\{0,\}$/\1/p"|sort -rV`;
    local new_version=`echo "$versions"|head -1`;

    if [ -z "$new_version" -o -z "$current_version" ];then
        echo -e "check php pecl ${ext} version \033[0;31mfaild\033[0m." >&2
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
                [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
                echo -e "PHP extension ${ext} version is \033[0;32mthe latest.\033[0m"
                return;
            else
                echo -e "PHP extension ${ext} current version: \033[0;33m${current_version}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
                return;
            fi
        elif [ "$ext" = "memcached" ];then
            if [ "$new_version" = "2.2.0" ];then
                [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
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
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
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
    #-H 'Upgrade-Insecure-Requests: 1'
    #-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Safari/537.36'
    # --compressed
    local new_version=`curl -Lk https://sourceforge.net/projects/${soft}/files/$( [ "${soft1}" = "0" ] || echo "${soft1}/" ) 2>/dev/null|sed -n "$pattern"|sort -rV|head -1`;
    if [ -z "$new_version" ];then
        echo -e "探测${soft}的新版本\033[0;31m失败\033[0m" >&2
        return 1;
    fi

    is_new_version $current_version $new_version
    if [ "$?" = "0" ];then
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
        echo -e "${soft} version is \033[0;32mthe latest.\033[0m"
        return 0;
    elif [ "$?" = "11" ] ; then
        return;
    fi

    echo -e "${soft} current version: \033[0;33m${current_version}\033[0m\tnew version: \033[0;35m${new_version}\033[0m"
}
# }}}
# {{{ function check_http_version()
function check_http_version()
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
        [ "$is_echo_latest" = "" -o "$is_echo_latest" != "0" ] && \
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
            "/sbin"
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
    if [ "$OS_NAME" != "darwin" ];then
        echo "this funtion[repair_dynamic_shared_library] not support  current OS[$OS_NAME]." >&2
        return;
    fi

    local dir1="$1"
    local filepattern="$2"
    local i=""
    local j=""
    for i in `find ${dir1} -type f $( [ "$filepattern" != "" ] && echo "-name $filepattern -type f")`;
    do
    {
        # 跳过软链接
        if [ -L "$i" ]; then
            continue;
        fi
        local filename="${i##*/}"
        for j in `otool -L $i|awk '{print $1; }' |grep -v '^/'|grep -v '^@'`;
        do
        {
            local filename1="${j##*/}"
            if [ "$filename" = "${filename1}" ];then
                if [ "${i%%/*}" != "" ];then
                    echo "file not is absolute path. file: $i " >&2
                    continue;
                fi
                install_name_tool -id $i $i;
                if [ "$?" != "0" ];then
                    echo "install_name_tool failed. file: $i " >&2
                    continue;
                fi
            else
                local num=`find $BASE_DIR -name ${filename1} |wc -l`;
                if [ "$num" = "0" ];then
                    echo "cant find file. filename: $j    file: $i" >&2
                    continue;
                elif [ "$num" != "1" ];then
                    echo "find more file with the same name. filename: $j  file: $i" >&2
                    continue;
                fi

                local f=`find $BASE_DIR -name ${filename1}|head -1`;

                local real_file=`realpath $f`

                local real_name=${real_file##*/}

                if [ "$filename" = "${real_name}" ];then
                    continue;
                fi

                repair_dynamic_shared_library $real_file
                if [ "$?" != "0" ];then
                    continue;
                fi

                install_name_tool -change  $j $f $i ;
                if [ "$?" != "0" ];then
                    echo "install_name_tool -change failed. filename: $j  file: $i replacefie: $f" >&2
                    continue;
                fi
            fi
        }
        done
    }
    done
}
# }}}
# {{{ repair elf file Linux下解决Library not loaded 问题
# {{{ function repair_dir_elf_rpath
function repair_dir_elf_rpath() {
    local path="$1"
    local i=""
    local j=""
    if [ -z "$path" -o ! -e "$path" ]; then
        echo "要修复的目录不存在" >&2
        return 1;
    fi
    path=`realpath "$path"`;
    if [ ! -d "$path" ];then
        echo "要修复的目录不存在" >&2
        return 1;
    fi

    IFS_old=$IFS
    IFS=$'\n'
    local path1=`find $path -type d \( -name lib -o -name -lib64 -o -name bin -o -name sbin \)`;
    if [ -z "$path1" ];then
        path1=$path
    fi
    for j in `echo "$path1"`;
    do
        for i in `find $j -type f`;
        do
            is_elf_file "$i"

            if [ "$?" != "0" ];then
                continue
            fi
            repair_elf_file_rpath "$i"
        done &
    done
    wait
    IFS=$IFS_old
}
# }}}
# {{{ function is_elf_file
function is_elf_file() {
    local filename="$1"
    if [ -z "$filename" -o ! -e "$filename" ];then
        echo "is_elf_file function: 文件[${filename}]不存在" >&2
        return 1;
    fi

    local signatures="ELF"
    if [ "$OS_NAME" = "darwin" ];then
        signatures="Mach-O"
    fi

    #file -b $filename |grep -q ELF
    file -b $filename|grep dynamically |grep -q ELF
}
# }}}
# {{{ function repair_elf_file_rpath
function repair_elf_file_rpath() {
    local filename=$1
    if [ -z "$filename" -o ! -e "$filename" ];then
        echo "要修复的文件不存在" >&2
        return 1;
    fi

    filename=`realpath "$filename"`;
    if [ ! -f "$filename" ];then
        echo "要修复的文件不存在" >&2
        return 1;
    fi

    is_elf_file "$filename"

    if [ "$?" != "0" ];then
        return 1;
    fi

    local tmp_str=`ldd $filename 2>/dev/null`;
    if echo "$tmp_str" |grep -q 'not found' ;then
        # 查找链接的所有so文件的目录
        local rpath=$(find_not_found_so_rpath "$filename" "$tmp_str")$(find_found_so_rpath "$tmp_str")
        rpath=${rpath%%:}
        # 修复文件
        # 相同目录
        # --set-rpath '$ORIGIN/'
        local CMD="$PATCHELF_BASE/bin/patchelf --set-rpath $rpath $filename"
        local error=""
        error=`$CMD 2>&1`;
        if [ "$?" = "1" ];then
            if echo $error|grep -q "open: Permission denied" ;then
                chmod u+w "$filename"
                if [ "$?" = "0" ] ;then
                    $CMD
                    if [ "$?" != "0" ] ;then
                        return 1
                    fi
                fi
            else
                echo $error >&2
                return 1;
            fi
        fi
        $PATCHELF_BASE/bin/patchelf --shrink-rpath $filename
    fi
}
# }}}
# {{{ function find_not_found_so_rpath
function find_not_found_so_rpath() {
    local filedir=`echo $1 |xargs dirname`
    shift
    local j=""
    # 没找到的so，查找文件所在目录
    for j in `echo "$@"|grep 'not found'|awk '{print $1;}'`;
    do
        local tmp=`find $BASE_DIR/ -name $j`;
        if [ "$tmp" != "" ];then
            tmp=`echo "$tmp" | xargs dirname`
            # if test `echo "$tmp"|awk 'END{print NR}'` -gt 1 ; then
            if test `echo "$tmp"|wc -l` -gt 1 ; then
                get_LCS_file $filedir "$tmp"
            else
                echo "$tmp"
            fi
        else
            echo "not find lib $j in $BASE_DIR " >&2
        fi
    done | sort -u | tr "\n" ":"
}
# }}}
# {{{ function find_found_so_rpath
function find_found_so_rpath() {
    # 能找到的so的目录
    echo "$tmp_str"|grep '=>' | grep '/' |grep -v 'not found'|awk '{print $3;}'|xargs dirname | sort -u | tr "\n" ":"
}
# }}}
# {{{ function get_LCS_file 获取和指定目录最近的目录
function get_LCS_file()
{
    local filedir="$1"
    shift

    # 查找最近的文件
    local filedir=`realpath $filedir`
    local max_subdir_num=0;
    local max_subdir=""

    local i="";
    local dir_arr=( `echo ${filedir#/}|tr '/' '\n'` )
    for i in `echo "$@"`;
    do
        local tmp_dir=`realpath $i`
        local tmp_arr=( `echo ${tmp_dir#/}|tr '/' '\n'` )
        local min_dir_num=${#dir_arr[@]}
        if [ "$min_dir_num" -gt "${#tmp_arr[@]}" ];then
            min_dir_num=${#tmp_arr[@]};
        fi
        local j=0;
        local m=0;
        for((; j<$min_dir_num; j++))
        do
            if [ "${dir_arr[j]}" = "${tmp_arr[j]}" ]; then
                ((m++))
            else
                break;
            fi
        done
        if [ "$max_subdir_num" -lt "$m" ]; then
            max_subdir_num=$m
            max_subdir=$i;
        fi
    done
    echo $max_subdir
}
# }}}
# }}}
# {{{ function multi_process() 多进程实现
function multi_process() {
    local task_name=$1
    local func_name=$2
    local thread_num=$3 # 最大可同时执行线程数量
    local job_num=$(($# - 3))    # 任务总数

    tmp_fifofile="/tmp/${task_name}_$$.fifo";
    mkfifo $tmp_fifofile ;      # 新建一个fifo类型的文件
    exec 6<>$tmp_fifofile ;     # 将fd6指向fifo类型
    rm $tmp_fifofile ;   #删也可以

    #根据线程总数量设置令牌个数
    for ((i=0;i<${thread_num};i++));do
        echo
    done >&6

    for ((i=4;i<=${job_num} + 4 - 1;i++));do # 任务数量
        # 一个read -u6命令执行一次，就从fd6中减去一个回车符，然后向下执行，
        # fd6中没有回车符的时候，就停在这了，从而实现了线程数量控制
        read -u6

        #可以把具体的需要执行的命令封装成一个函数
        {
            $func_name ${!i}
            echo >&6 # 当进程结束以后，再向fd6中加上一个回车符，即补上了read -u6减去的那个
        } &
    done

    wait
    exec 6>&- # 关闭fd6
}
# }}}
# {{{ function ping_usable() # 测试当前网络下是否可以连接到某域名
function ping_usable()
{
    local domain_name=$1
    local threshold=$2
    if [ "$threshold" = "" ]; then
        threshold="60"
    fi
    local status=`ping -c 5 -q $domain_name -i 0.001|sed -n '$p' |awk -F/ "{ if ( \\$6 < 0 || \\$6 > $threshold ) { print 1; } else { print 0;} ;}"`
    return $status
}
# }}}
# {{{ function init_setup() #
function init_setup()
{
    mkdir -p $BASE_DIR/setup
    cp $curr_dir/base_define.sh $BASE_DIR/setup/
    chmod u+x $BASE_DIR/setup/base_define.sh
    #sed -i.bak.$$ '/^.\{1,\}_VERSION=/d;/^.\{1,\}_FILE_NAME/d' $BASE_DIR/setup/base_define.sh
    sed -i.bak.$$ '/^# {{{ open source libray version info/,/^# }}}/d' $BASE_DIR/setup/base_define.sh
    sed -i.bak.$$ '/^# {{{ open source libray file name/,/^# }}}/d' $BASE_DIR/setup/base_define.sh
    rm -rf $BASE_DIR/setup/base_define.sh.bak.*

    cp -r $curr_dir/setup/* $BASE_DIR/setup/
    chmod u+x $BASE_DIR/setup/*.sh
}
# }}}
#wget --content-disposition --no-check-certificate https://github.com/vrtadmin/clamav-devel/archive/clamav-0.99.2.tar.gz
#tar zxf clamav-devel-clamav-0.99.2.tar.gz
#cd clamav-devel-clamav-0.99.2
#./configure --prefix=$OPT_BASE/clamav --with-openssl=$OPENSSL_BASE --with-pcre=$PCRE_BASE --with-zlib=$ZLIB_BASE --with-libbz2-prefix=$LIBBZ2_BASE --with-iconv --with-libcurl=$CURL_BASE
#./configure --prefix=$OPT_BASE/clamav --with-openssl=$OPENSSL_BASE --with-pcre=$PCRE_BASE --with-zlib=$ZLIB_BASE --with-libbz2-prefix=$LIBBZ2_BASE --with-iconv --with-libcurl=$CURL_BASE --with-xml=$LIBXML2_BASE
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
# GeoLite2国家和城市数据库在每个月的第一个星期二更新。GeoLite2 ASN数据库每周二更新一次。
# 时差
#0 5 * * 3 $GEOIPUPDATE_BASE/bin/geoipupdate >/dev/null 2>&1 &

# 问题，及解决方法
#libtoolize --quiet
#libtoolize: `COPYING.LIB' not found in `/usr/share/libtool/libltdl'
#yum install libtool-ltdl-devel



#https://imququ.com/post/letsencrypt-certificate.html
# https://imququ.com/post/ecc-certificate.html
#https://github.com/masterzen/nginx-upload-progress-module/releases
# https://github.com/vkholodkov/nginx-upload-module/releases
# http://nginx.org/en/docs/http/ngx_http_v2_module.html

#https://imququ.com/post/letsencrypt-certificate.html
#https://github.com/diafygi/acme-tiny

#https://github.com/exinnet/tclip

# 域名后缀列表
#https://publicsuffix.org/list/public_suffix_list.dat
#cp -r contrib/vim ~/.vim/bundle/nginx

# vim

#wget --no-check-certificate --content-disposition https://github.com/vim/vim/archive/v8.0.0771.tar.gz

#tar zxf vim-8.0.0771.tar.gz
#cd vim-8.0.0771

#yum install perl python ruby perl-devel python-devel ruby-devel lua lua-devel perl-ExtUtils-Embed

#./configure --prefix=/opt/vim800 --enable-luainterp=yes --enable-perlinterp=yes --enable-pythoninterp=yes --enable-rubyinterp=yes --enable-multibyte
#./configure --enable-gui=no --without-x

#wget --no-check-certificate --content-disposition https://github.com/swig/swig/archive/rel-3.0.12.tar.gz
#tar zxf swig-rel-3.0.12.tar.gz
#cd swig-rel-3.0.12
#./autogen.sh
#./configure --prefix=$OPT_BASE/swig --with-php=$PHP_BASE/bin
#make
#make install
#cd ..
#rm -rf swig-rel-3.0.12

