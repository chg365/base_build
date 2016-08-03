#!/bin/bash

curr_dir=$(cd "$(dirname "$0")"; pwd);
#otool -L
#brew install

base_define_file=$curr_dir/base_define.sh

if [ ! -f $base_define_file ]; then
echo "can't find base_define.sh";
exit 1;
fi

base_function_file=$curr_dir/base_function.sh
if [ ! -f $base_function_file ];then
echo "can't find base_function.sh"
exit 1;
fi

. $base_define_file
. $base_function_file

################################################################################
# environment check
################################################################################
# {{{ sudo 配置
if  sudo grep -q '^Defaults    requiretty' /etc/sudoers ;then
    echo "后台执行可能会报错: sudo：抱歉，您必须拥有一个终端来执行 sudo ";
	echo "解决此问题可能要执行命令： sudo sed -i 's/^Defaults    requiretty/#Defaults    requiretty/g' /etc/sudoers"
	exit 1;
fi;
# }}}
# {{{ cmake
if [ "$OS_NAME" = 'Darwin' ];then
    which brew > /dev/null 2>&1
    if [ $? -ne 0 ];then
        echo "缺少工具brew."
        exit;
    fi
fi
which cmake > /dev/null 2>&1
if [ $? -ne 0 ];then
    echo "缺少工具cmake."
    if [ "$OS_NAME" = 'Linux' ];then
        echo "linux下执行： sudo yum install cmake 安装";
    else
        echo "执行: brew install cmake 安装";
    fi
    exit;
fi
# }}}
# {{{ docbook2pdf fontconfig需要
# fontconfig需要工具
function check_docbook2pdf()
{
    if [ "$OS_NAME" != 'Darwin' ];then
        which docbook2pdf > /dev/null 2>&1;

        if [ $? -ne 0 ];then
            echo "缺少工具docbook2pdf." >&2
            if [ "$OS_NAME" = 'Linux' ];then
                echo "linux下执行： sudo yum install docbook-utils-pdf 安装";
            else
                echo "需要安装 docbook-utils-pdf";
            fi
            return 1;
        fi
    fi
}
# }}}
# sed {{{
# sed 版本检测 mac中 BSD版本 -i参数，如果不备份，后面必须有 ''
# 以下方式没有实现，先用 -i.bak.$$的方式实现，最后删除这些备份
sed_ver="GNU"
sed_i="-i"
if [ "$OS_NAME" = "Darwin" ];then
    sed --versioin > /dev/null 2>&1
    if [ "$?" = "1" ];then
        sed_ver="BSD"
        sed_i="-i ''"
    fi
fi
# }}}
###################################################################################################
export PATH="$( [ "$OS_NAME" = 'Darwin' ] && [ -d "/usr/local/opt/bison/bin" ] && echo " -L/usr/local/opt/bison/bin" ):$CONTRIB_BASE/bin:$PATH"
# PATH="$CONTRIB_BASE/bin:$PATH"

mkdir -p $HOME/$project_abbreviation/pkgs
cd $HOME/$project_abbreviation/pkgs

wget_base_library
################################################################################
# Check BASE DIR
################################################################################
#if [ -d $BASE_DIR ]; then
#    echo "The install dir '$BASE_DIR' exists, please remove it, exit now"
#    exit 1;
#fi
sudo mkdir -p $BASE_DIR
sudo chown -R `whoami` $BASE_DIR

if uname -a|grep -q x86_64 ; then
	export KERNEL_BITS=64
fi


################################################################################
export LC_CTYPE=C 
export LANG=C
pkg_config_path_init
compile_zeromq
compile_zlib
compile_libgd
compile_php
compile_memcached
compile_php_extension_imagick
#compile_php_extension_dio
compile_php_extension_pthreads
compile_php_extension_qrencode
#compile_php_extension_zeromq
compile_php_extension_intl
#compile_php_extension_apcu
compile_php_extension_apcu_bc
#compile_php_extension_memcached
compile_php_extension_event
#compile_php_extension_libevent
compile_php_extension_libsodium
compile_php_extension_yaf
compile_php_extension_xdebug
compile_php_extension_raphf
compile_php_extension_propro
compile_php_extension_pecl_http
compile_php_extension_amqp
compile_php_extension_mailparse
compile_php_extension_redis
compile_php_extension_solr
compile_php_extension_mongodb
compile_php_extension_swoole
compile_php_extension_memcached
compile_mysql

$PHP_BASE/bin/php --ini

/bin/rm -rf $php_ini.bak.$$
/bin/rm -rf $mysql_cnf.bak.$$

exit;
cp $php_ini $PHP_CONFIG_DIR/php-cli.ini

sed -i '/extension=pthreads.so/d' $php_ini
################################################################################
# Install SWFUpload
################################################################################
#echo_build_start SWFUpload
#unzip "SWFUpload v$SWFUPLOAD_VERSION Core.zip"
#mkdir -p $SWFUPLOAD_BASE
#cd "SWFUpload v$SWFUPLOAD_VERSION Core"
#cp swfupload.js Flash/swfupload.swf plugins/*js $SWFUPLOAD_BASE/
#sed -i.bak '/allowScriptAccess/s/value="always"/value="sameDomain"/' $SWFUPLOAD_BASE/swfupload.js
#cd ..

#/bin/rm -rf "SWFUpload v$SWFUPLOAD_VERSION Core"

################################################################################
# Install drupal 
################################################################################
#wget --no-check-certificate --content-disposition https://github.com/laravel/laravel/archive/master.zip
#wget http://ftp.drupal.org/files/projects/drupal-7.38.tar.gz
################################################################################
# END
################################################################################

#wget  http://xquartz.macosforge.org/downloads/SL/XQuartz-2.7.7.dmg

#	hdiutil attach Quartz-2.7.7.dmg

    # 一般会自动装载到 /Volumes 下
#	cd /Volumes/Quartz-2.7.7

    # 用系统管理员权限安装 目标文件夹 “/Application”
#	sudo installer -pkg Quartz-2.7.7.pkg -target /Application

    # 卸载 Dmg
#	hdiutil detach /Volumes/Quartz-2.7.7/



#tar zxf XQuartz-2.7.9.tar.gz
#cd xorg-server-XQuartz-2.7.9/
#./autogen.sh
#./configure 





#wget http://download.savannah.gnu.org/releases/acl/acl-2.2.52.src.tar.gz
##yum install libacl libacl-devel
#yum install libattr libattr-devel
#tar zxf acl-2.2.52.src.tar.gz
#cd acl-2.2.52
#./configure --prefix=/usr/local/chg/base/opt/acl --enable-lib64=yes
#make
#make install
#cd ..





# php dba ext
#./configure --with-php-config=/usr/local/chg/base/opt/php/bin/php-config  --enable-dba=shared --with-qdbm= --with-gdbm= --with-ndbm= --with-db4= --with-dbm= --with-tcadb=


#https://www.mongodb.com/
#https://fastdl.mongodb.org/src/mongodb-src-r3.2.8.tar.gz?_ga=1.116392006.1520954878.1468772281

LIBXSLT_VERSION="1.1.29"
LIBXSLT_FILE_NAME="libxslt-${LIBXSLT_VERSION}.tar.gz"
TIDY_VERSION="5.2.0"
TIDY_FILE_NAME="tidy-html5-${TIDY_VERSION}.tar.gz"
wget https://github.com/htacg/tidy-html5/archive/${TIDY_VERSION}.tar.gz
wget ftp://xmlsoft.org/libxslt/$LIBXSLT_FILE_NAME

tar zxf libxslt-1.1.29.tar.gz
cd libxslt-1.1.29
./configure --prefix=/usr/local/chg/base/contrib/ --with-libxml-prefix=
./configure --prefix=/usr/local/chg/base/contrib/
make
make install
cd ..
rm -rf libxslt-1.1.29

tar zxf tidy-html5-5.2.0.tar.gz
cd tidy-html5-5.2.0/build/cmake/
export PATH="/usr/local/chg/base/contrib/bin:$PATH"
cmake ../.. -DCMAKE_INSTALL_PREFIX=/usr/local/chg/base/contrib
make
make install
cd ../../../
rm -rf tidy-html5-5.2.0




tar Jxf php-7.0.7.tar.xz
cd php-7.0.7/ext/tidy
/usr/local/chg/base/opt/php/bin/phpize
./configure --with-php-config=/usr/local/chg/base/opt/php/bin/php-config --with-tidy=/usr/local/chg/base/contrib
sed -i 's/\<buffio.h/tidybuffio.h/' tidy.c
make
make install
ldd /usr/local/chg/base/opt/php/lib/php/extensions/no-debug-zts-20151012/tidy.so
cd ../../..
rm -rf php-7.0.7


wget --content-disposition --no-check-certificate https://github.com/sphinxsearch/sphinx/archive/2.2.10-release.tar.gz
tar zxf sphinx-2.2.10-release.tar.gz
cd sphinx-2.2.10-release
./configure --prefix=/usr/local/chg/base/opt/sphinx --with-mysql=/usr/local/chg/base/opt/mysql
make && make install
cd ..
rm -rf sphinx-2.2.10-release

tar zxf sphinx-2.2.10-release.tar.gz
cd sphinx-2.2.10-release/api/libsphinxclient/
./configure --prefix=/usr/local/chg/base/contrib
make && make install
cd ../../
cd ..
rm -rf sphinx-2.2.10-release

wget --content-disposition --no-check-certificate https://github.com/php/pecl-search_engine-sphinx/archive/php7.tar.gz
tar zxf pecl-search_engine-sphinx-php7.tar.gz
cd pecl-search_engine-sphinx-php7
/usr/local/chg/base/opt/php/bin/phpize
./configure --with-php-config=/usr/local/chg/base/opt/php/bin/php-config --with-sphinx=/usr/local/chg/base/contrib
make && make install
ldd /usr/local/chg/base/opt/php/lib/php/extensions/no-debug-zts-20151012/sphinx.so





wget http://pecl.php.net/get/geoip-1.1.0.tgz


http://stock.qq.com/a/20160718/005704.htm

wget --content-disposition --no-check-certificate https://github.com/maxmind/geoip-api-c/releases/download/v1.6.9/GeoIP-1.6.9.tar.gz
wget --content-disposition --no-check-certificate  https://github.com/maxmind/geoip-api-c/archive/v1.6.9.tar.gz
tar zxf geoip-api-c-1.6.9.tar.gz
cd geoip-api-c-1.6.9
#./bootstrap
./configure --prefix=/usr/local/chg/base/contrib
make
make install



wget --content-disposition --no-check-certificate https://github.com/Zakay/geoip/archive/master.tar.gz
tar zxf geoip-master.tar.gz
cd geoip-master
/usr/local/chg/base/opt/php/bin/phpize
./configure --with-php-config=/usr/local/chg/base/opt/php/bin/php-config --with-geoip=/usr/local/chg/base/contrib
make
make install
ldd /usr/local/chg/base/opt/php/lib/php/extensions/no-debug-zts-20151012/geoip.so

