#!/bin/sh

curr_dir=$(cd "$(dirname "$0")"; pwd);

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


re2c_version="0.13.4"
which re2c 1>/dev/null 2>/dev/null
if [ "$?" != "0" ];then
    echo "You will need re2c ${re2c_version} or later" >&2
    exit 1;
fi
re2c_version1=`re2c --version|awk '{print $2;}'`;
re2c_version2=`echo "${re2c_version}" "${re2c_version1}"|tr " " "\n"|sort -V|head -1`
if [ "$re2c_version2" != "$re2c_version" ];then
    echo "You will need re2c ${re2c_version} or later" >&2
    exit 1;
fi

autoconf_version=`autoconf --version|head -1|awk '{ print $NF; }'`
if [ `echo "$autoconf_version 2.63"|tr " " "\n"|sort -rV|head -1` = "2.63" ] ; then
    echo "autoconf version 2.64 or higher is required" >&2
    exit 1;
fi
export LANG=en_US.utf8
#export LANG=zh_CN.utf8
#export LC_CTYPE=C
#export LC_ALL=en_US.utf8

echo `date "+%Y-%m-%d %H:%M:%S"` start
start_time=`date +%s`

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
which cmake > /dev/null 2>&1
if [ $? -ne 0 ];then
    echo "缺少工具cmake."
    if [ "$OS_NAME" = 'linux' ];then
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
    if [ "$OS_NAME" != 'darwin' ];then
        which docbook2pdf > /dev/null 2>&1;

        if [ $? -ne 0 ];then
            echo "缺少工具docbook2pdf." >&2
            if [ "$OS_NAME" = 'linux' ];then
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
if [ "$OS_NAME" = "darwin" ];then
    sed --versioin > /dev/null 2>&1
    if [ "$?" = "1" ];then
        sed_ver="BSD"
        sed_i="-i ''"
    fi
fi
# }}}
###################################################################################################

if [ "$PKGS_DIR" = "" ] || echo "$PKGS_DIR" |grep -qv ^$HOME ;
then
    echo "使用或下载的软件目录未定义!" >&2
    exit 1;
fi
if [ ! -d "$PKGS_DIR" ];
then
    mkdir -p $PKGS_DIR
fi
cd $PKGS_DIR

################################################################################
# Check BASE DIR
################################################################################
#if [ -d $BASE_DIR ]; then
#    echo "The install dir '$BASE_DIR' exists, please remove it, exit now"
#    exit 1;
#fi
if [ ! -d $BASE_DIR ]; then
    sudo mkdir -p $BASE_DIR
    sudo chown -R `whoami` $BASE_DIR
fi

if uname -a|grep -q x86_64 ; then
	export KERNEL_BITS=64
fi


################################################################################
pkg_config_path_init
if [ "$OS_NAME" = 'darwin' ];then
    for i in `find /usr/local/Cellar/ -mindepth 0 -maxdepth 3 -a \( -name bin -o -name sbin \) -type d`;
    do
        i=${i%/*}
        deal_path $i
    done
fi

# 检测开源软件新版本
#check_soft_updates
#exit;
# 下载开源软件新版本
wget_base_library

#compile_python
compile_xunsearch
#compile_xapian_core
compile_xapian_omega
if [ "$OS_NAME" != 'darwin' ];then
    # mac下 这个软件不能用
    compile_patchelf
fi
compile_nodejs
compile_openssl
#compile_ImageMagick
compile_redis
#  error: Leptonica 1.74 or higher is required. Try to install libleptonica-dev package.
#compile_tesseract # 图片文字识别 OCR （Optical Character Recognition，光学字符识别）
#compile_libunwind
compile_zeromq
compile_zlib
compile_libgd
#compile_apache
compile_postgresql
compile_pgbouncer
compile_php
compile_memcached
#compile_sphinx
#compile_mysql
compile_nginx
#compile_stunnel
compile_sqlite
compile_gearmand
#compile_phantomjs
if [ "$OS_NAME" != "darwin" ]; then
    gcc_minimum_version="4.7.99"
    gcc_version=`gcc --version 2>/dev/null|head -1|awk '{ print $3;}'`;
    gcc_new_version=`echo $gcc_version $gcc_minimum_version|tr " " "\n"|sort -rV|head -1`;
    if [ "$gcc_new_version" != "$gcc_minimum_version" ]; then
        #compile_pdf2htmlEX
        :
    fi
    compile_php_extension_gearman
    compile_logrotate
fi
#compile_rsyslog
#compile_php_extension_zip
compile_php_extension_dio
compile_php_extension_trader
#compile_php_extension_pthreads
compile_php_extension_parallel
compile_php_extension_qrencode
compile_php_extension_zeromq
compile_php_extension_intl
compile_php_extension_apcu
#compile_php_extension_apcu_bc
compile_php_extension_event
#compile_php_extension_libevent
compile_php_extension_libsodium
compile_php_extension_yaf
compile_php_extension_psr
compile_php_extension_phalcon
compile_php_extension_xdebug
compile_php_extension_raphf
compile_php_extension_propro
compile_php_extension_pecl_http
compile_php_extension_amqp
compile_php_extension_mailparse
compile_php_extension_redis
compile_php_extension_solr
compile_php_extension_mongodb
compile_php_extension_pdo_pgsql
compile_php_extension_swoole
if [ "$gcc_new_version" = "" -o "$gcc_new_version" != "$gcc_minimum_version" ]; then
    compile_php_extension_grpc
    compile_php_extension_protobuf
fi
compile_php_extension_memcached
compile_php_extension_tidy
#compile_php_extension_sphinx
compile_php_extension_imagick
compile_php_extension_scws
compile_xapian_bindings_php
# geoip2
compile_libmaxminddb
compile_php_extension_maxminddb
compile_geoipupdate
#compile_php_extension_imap
install_dehydrated
cp_GeoLite2_data
#install_web_service_common_php #无用
install_geoip2_php
#compile_gitbook_cli

# ebook
#compile_calibre

compile_smarty
compile_yii2
compile_yii2_smarty
#compile_parseapp
#compile_htmlpurifier

$PHP_BASE/bin/php --ini

/bin/rm -rf $php_ini.bak.$$
#/bin/rm -rf $mysql_cnf.bak.$$


echo `date "+%Y-%m-%d %H:%M:%S"` end
end_time=`date +%s`
echo "used times: $((end_time - start_time))s"

echo $LD_LIBRARY_PATH
#[ "$OS_NAME" = "linux" ] && repair_dir_elf_rpath $BASE_DIR
[ "$OS_NAME" != "linux" ] || repair_dir_elf_rpath $BASE_DIR
#repair_file_rpath $LIBICU_BASE/lib/libicutu.so
#repair_elf_file_rpath $LIBICU_BASE/lib/libicutu.so
init_setup
################################################################################
# Install javascript lib
################################################################################
compile_jquery
compile_d3
compile_chartjs
compile_ckeditor
compile_famous
compile_famous_angular

#cp $php_ini $PHP_CONFIG_DIR/php-cli.ini

sed -i.bak.$$ '/extension=pthreads.so/d' $php_ini
rm -rf ${php_ini}.bak*

# 测试index.php
cp $curr_dir/../src/web/index.php $WEB_BASE/

# 容易出错，放这里
#compile_gitbook_cli
#$PYTHON_BASE/bin/pip3 install --upgrade pip
#中文分词
#$PYTHON_BASE/bin/pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple  -U pkuseg
#$PYTHON_BASE/bin/pip3 install -U pkuseg
#tensorflow
#$PYTHON_BASE/bin/pip3 install --upgrade tensorflow
exit;
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
#./configure --prefix=$OPT_BASE/acl --enable-lib64=yes
#make
#make install
#cd ..





# php dba ext
#./configure --with-php-config=$PHP_BASE/bin/php-config  --enable-dba=shared --with-qdbm= --with-gdbm= --with-ndbm= --with-db4= --with-dbm= --with-tcadb=

#wget --content-disposition --no-check-certificate https://github.com/FoolCode/SphinxQL-Query-Builder/archive/0.0.2.tar.gz
# http://stock.qq.com/a/20160718/005704.htm


wget http://pecl.php.net/get/geoip-1.1.0.tgz
https://github.com/leev/ngx_http_geoip2_module
wget --content-disposition --no-check-certificate https://github.com/maxmind/geoip-api-c/releases/download/v1.6.9/GeoIP-1.6.9.tar.gz
wget --content-disposition --no-check-certificate  https://github.com/maxmind/geoip-api-c/archive/v1.6.9.tar.gz
tar zxf geoip-api-c-1.6.9.tar.gz
cd geoip-api-c-1.6.9
#./bootstrap
./configure --prefix=$GEOIP_BASE
make
make install



wget --content-disposition --no-check-certificate https://github.com/Zakay/geoip/archive/master.tar.gz
tar zxf geoip-master.tar.gz
cd geoip-master
$PHP_BASE/bin/phpize
./configure --with-php-config=$PHP_BASE/bin/php-config --with-geoip=$GEOIP_BASE
make
make install
ldd $PHP_BASE/lib/php/extensions/no-debug-zts-20151012/geoip.so



http://www.rabbitmq.com/releases/rabbitmq-server/v3.6.5/rabbitmq-server-3.6.5.tar.xz
wget --content-disposition --no-check-certificate https://github.com/phpDocumentor/phpDocumentor2/archive/v2.9.0.tar.gz


#https://www.x.org/releases/individual/lib/libXft-2.3.2.tar.bz2

ftp://ftp.cyrusimap.org/cyrus-sasl/
ftp://ftp.cyrusimap.org/cyrus-imapd/
https://www.cyrusimap.org/sasl/sasl/installation.html#quick-install-guide


https://github.com/nesk/rialto
https://github.com/nesk/PuPHPeteer


SQL中继
数据库池连接代理服务器
http://downloads.sourceforge.net/rudiments/rudiments-1.2.2.tar.gz
http://downloads.sourceforge.net/sqlrelay/sqlrelay-1.7.0.tar.gz
