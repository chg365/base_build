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

#shopt | grep huponexit
#disown
# screen tmux
# autoconf，automake，autopoint，pkg-config
#wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
if [ ! -f $HOME/.chg_base_compile_env -a "$OS_NAME" = "linux" ]; then
    yum install -y cmake gcc xz texinfo bzip2 xz-devel gcc-c++ ncurses-devel ncurses byacc file re2c libtool-ltdl-devel popt-devel re2c wget curl libtool
    yum install -y curl nss cyrus-sasl cyrus-sasl-devel cyrus-sasl-lib libacl libacl-devel libattr libattr-devel gperf pam pam-devel krb5-devel krb5-libs uuid uuid-devel

    #wget http://dl.fedoraproject.org/pub/epel/7/x86_64/r/re2c-0.14.3-2.el7.x86_64.rpm
    yum install -y autoconf m4 automake pkg-config gettext-devel

    if uname -r|grep -q 'el7' ;then
        yum -y install systemd-devel
    fi

    touch $HOME/.chg_base_compile_env
fi

#tar Jxf m4-1.4.17.tar.xz
#cd m4-1.4.17
#./configure && make && make install
#cd ..
#rm -rf m4-1.4.17

#tar zxf autoconf-2.69.tar.gz
#cd autoconf-2.69
#./configure && make && make install
#cd ..
#rm -rf autoconf-2.69

#tar Jxf automake-1.15.tar.xz
#cd automake-1.15
#./configure && make && make install
#cd ..
#rm -rf automake-1.15

#tar Jxf libtool-2.4.6.tar.xz
#cd libtool-2.4.6
#./configure && make && make install
#cd ..
#rm -rf libtool-2.4.6

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
    echo "Autoconf version 2.64 or higher is required" >&2
    exit 1;
fi
export LANG=C
export LC_ALL=C
 
echo `date "+%Y-%d-%m %H:%M:%S"` start
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
if [ "$OS_NAME" = 'darwin' ];then
    which brew > /dev/null 2>&1
    if [ $? -ne 0 ];then
        echo "缺少工具brew."
        exit;
    fi
fi
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
#check_soft_updates
#exit;
#compile_gitbook_pdf
#exit;
compile_patchelf
compile_nodejs
compile_openssl
compile_ImageMagick
compile_redis
#compile_libunwind
compile_zeromq
compile_zlib
compile_libgd
compile_apache
compile_php
compile_memcached
compile_sphinx
compile_mysql
compile_nginx
compile_sqlite
compile_phantomjs
if [ "$OS_NAME" != 'darwin' ];then
    gcc_minimum_version="4.7.99"
    gcc_version=`gcc --version 2>/dev/null|head -1|awk '{ print $3;}'`;
    gcc_new_version=`echo $gcc_version $gcc_minimum_version|tr " " "\n"|sort -rV|head -1`;
    if [ "$gcc_new_version" != "$gcc_minimum_version" ]; then
        compile_pdf2htmlEX
    fi
    compile_php_extension_gearman
    compile_logrotate
fi
compile_rsyslog
compile_php_extension_dio
compile_php_extension_pthreads
compile_php_extension_qrencode
compile_php_extension_zeromq
compile_php_extension_intl
compile_php_extension_apcu
compile_php_extension_apcu_bc
compile_php_extension_event
#compile_php_extension_libevent
compile_php_extension_libsodium
compile_php_extension_yaf
compile_php_extension_phalcon
compile_php_extension_xdebug
compile_php_extension_raphf
compile_php_extension_propro
# 编译上这个后，pthreads 报 段错误  3.1.0
#compile_php_extension_pecl_http
compile_php_extension_amqp
compile_php_extension_mailparse
compile_php_extension_redis
compile_php_extension_solr
compile_php_extension_mongodb
compile_php_extension_swoole
if [ "$gcc_new_version" != "$gcc_minimum_version" ]; then
    compile_php_extension_grpc
    compile_php_extension_protobuf
fi
compile_php_extension_memcached
compile_php_extension_tidy
compile_php_extension_sphinx
compile_php_extension_imagick
# geoip2
compile_libmaxminddb
compile_php_extension_maxminddb
compile_geoipupdate
compile_php_extension_imap
install_dehydrated
cp_GeoLite2_data
install_web_service_common_php
install_geoip2_php
compile_gitbook_cli
#compile_gitbook_pdf
compile_calibre

$PHP_BASE/bin/php --ini

/bin/rm -rf $php_ini.bak.$$
/bin/rm -rf $mysql_cnf.bak.$$


echo `date "+%Y-%d-%m %H:%M:%S"` end
end_time=`date +%s`
echo "used times: $((end_time - start_time))s"

echo $LD_LIBRARY_PATH
#[ "$OS_NAME" = "linux" ] && repair_dir_elf_rpath $BASE_DIR
[ "$OS_NAME" != "linux" ] || repair_dir_elf_rpath $BASE_DIR
#repair_file_rpath $LIBICU_BASE/lib/libicutu.so
#repair_elf_file_rpath $LIBICU_BASE/lib/libicutu.so
init_setup
cp $php_ini $PHP_CONFIG_DIR/php-cli.ini

sed -i.bak.$$ '/extension=pthreads.so/d' $php_ini
rm -rf ${php_ini}.bak*
exit;
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

#wget --content-disposition --no-check-certificate https://github.com/FoolCode/SphinxQL-Query-Builder/archive/0.0.2.tar.gz
# http://stock.qq.com/a/20160718/005704.htm


wget http://pecl.php.net/get/geoip-1.1.0.tgz
https://github.com/leev/ngx_http_geoip2_module
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



http://www.rabbitmq.com/releases/rabbitmq-server/v3.6.5/rabbitmq-server-3.6.5.tar.xz
wget --content-disposition --no-check-certificate https://github.com/phpDocumentor/phpDocumentor2/archive/v2.9.0.tar.gz


#https://www.x.org/releases/individual/lib/libXft-2.3.2.tar.bz2

ftp://ftp.cyrusimap.org/cyrus-sasl/
ftp://ftp.cyrusimap.org/cyrus-imapd/
https://www.cyrusimap.org/sasl/sasl/installation.html#quick-install-guide
