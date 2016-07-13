#!/bin/bash

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
        echo "Install ${@#*/} failed.";
        exit 1;
    fi

    make && make install

    if [ $? -ne 0 ];then
        echo "Install ${@#*/} failed.";
        exit 1;
    fi
}
# }}}
# function is_finished_wget() {{{ 判断wget 下载文件是否成功
function is_finished_wget()
{
    if [ "${1%/*}" != "0" ];then
        echo "wget file ${@#*/} failed.";
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
    return $?;

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
        $PHP/bin/phpize
        if [ "$?" != "0" ];then
            exit 1;
        fi
    fi

    echo "configure command: "
    eval echo "\$$COMMAND"
    echo ""
    ${!COMMAND}
    # eval "\$$COMMAND"

    make_run "$?/$NAME"

    # cd ../
    cd -
    if [ "$?" != 0 ];then
        echo "cd dir error. command: cd -; pwd:`pwd`" >&2
        exit 1;
    fi
    local tmp_str=${FILE_DIR%%/*};
    if [ -z "$tmp_str" ] || [ "$tmp_str" = "." ] || [ "$tmp_str" = ".." ];then
        echo "m  dir error. pwd:`pwd` file_dir: ${FILE_DIR} tmp_str: ${tmp_str}" >&2
        exit 1;
    fi
    # /bin/rm -rf $FILE_DIR
    /bin/rm -rf $tmp_str

    if [ "$?" != 0 ];then
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
function version_compare()
{
    return 0;
    return 1;
}

# {{{ function pkg_config_path_init()
function pkg_config_path_init()
{
    local tmp_arr=( "/usr/lib64/pkgconfig" "/usr/share/pkgconfig" "/usr/lib/pkgconfig" "/usr/local/lib/pkgconfig" );
    local i=""
    for i in ${tmp_arr[@]}; do
    {
        if [ -d "$i" ];then
            PKG_CONFIG_PATH="$i:$PKG_CONFIG_PATH";
        fi
    }
    done

    PKG_CONFIG_PATH=${PKG_CONFIG_PATH%:}
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
        for j in `find $i -name pkgconfig -type d -mindepth 0 -maxdepth 2`;
        do
            echo ${PKG_CONFIG_PATH}: |grep -q "$j:";
            if [ "$?" != 0 ];then
                PKG_CONFIG_PATH="$j:$PKG_CONFIG_PATH"
            fi
        done
    done

    if [ "$j" = "" ];then
        echo "ERROR: deal_pkg_config_path parameter error. value: $*  dir is not find pkgconfig dir." >&2
        return 0;
        #return 1;
    fi
}
# }}}
export PATH="$COMPILE_BASE/bin:$CONTRIB_BASE/bin:$PATH"
