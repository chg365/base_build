#!/bin/sh


curr_dir=$(cd "$(dirname "$0")"; pwd);
#otool -L
#brew install

# {{{ yum install OR brew install
if [ ! -f $HOME/.chg_base_compile_env ]; then
    sudo yum install -y cmake gcc texinfo gcc-c++ bison ncurses-devel ncurses byacc \
                        libtool-ltdl-devel popt-devel re2c wget curl libtool coreutils nasm make
    sudo yum install -y curl nss cyrus-sasl cyrus-sasl-devel cyrus-sasl-lib libacl libacl-devel \
                        libattr libattr-devel gperf pam pam-devel krb5-devel krb5-libs \
                        libmount libmount-devel libuuid-devel libuuid  zlib-devel readline-devel bzip2-devel \
                        gdbm-devel unzip

    sudo yum install -y itstool patch # fontconfig 2.12.91

    sudo yum install -y xz bzip2 tar \
                        xz-devel

    #postgresql
    sudo yum install -y uuid \
                        uuid-devel

    sudo yum install -y libacl       libattr       mariadb-libs  readline       ncurses \
                        libuuid        cyrus-sasl cyrus-sasl-lib  pam       popt \
                        libacl-devel libattr-devel mariadb-devel readline-devel ncurses-devel \
                        libuuid-devel  cyrus-sasl-devel           pam-devel popt-devel
    # xapian-omega
    sudo yum install -y file \
                        file-devel

    # Python
    sudo yum install -y expat       libffi       tcl       tk \
                        expat-devel libffi-devel tcl-devel tk-devel

    #wget http://dl.fedoraproject.org/pub/epel/7/x86_64/r/re2c-0.14.3-2.el7.x86_64.rpm
    sudo yum install -y autoconf m4 automake pkg-config gettext-devel meson mariadb-devel

    tmp_str=`uname -r|awk -F. '{print $(NF-1);}'|sed -n 's/el//p'`; # 6 7 8
    if echo $tmp_str |grep -q '^[0-9]\{1,\}$'  ;then
        if [ "$tmp_str" -qt 6 ] ;then
            sudo yum -y install systemd-devel
        fi
    fi
    elif [ "$OS_NAME" = "darwin" ];then
        # curl: (56) SSLRead() return error -9841
        brew install nasm && \
        brew link curl --force && \
        brew install --with-openssl curl && \
        brew link curl --force && \
        brew install --with-openssl wget && \
        brew link wget --force && \
        brew install re2c && \
        brew link re2c --force && \
        brew install libtool && \
        brew link libtool --overwrite && \
        brew install cmake && \
        brew link cmake --overwrite && \
        brew install pkg-config && \
        brew link pkg-config --overwrite && \
        brew install itstool && \
        brew link itstool --overwrite && \
        brew install automake && \
        brew link automake --overwrite && \
        brew install ossp-uuid && \
        brew link ossp-uuid --overwrite && \
        brew install mariadb-devel && \
        brew link mariadb-devel --overwrite && \
        brew install libmagic && \
        brew install unzip && \
        brew install autoconf && \
        brew link autoconf --overwrite
    fi

    touch $HOME/.chg_base_compile_env
fi
# }}}

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
    echo "autoconf version 2.64 or higher is required" >&2
    exit 1;
fi
export LANG=en_US.utf8
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
#export LC_CTYPE=C
#export LANG=C
pkg_config_path_init
if [ "$OS_NAME" = 'darwin' ];then
    for i in `find /usr/local/Cellar/ -mindepth 0 -maxdepth 3 -a \( -name bin -o -name sbin \) -type d`;
    do
        i=${i%/*}
        deal_path $i
    done
fi
#wget https://www.rarlab.com/rar/rarlinux-x64-5.5.0.tar.gz
#wget https://www.rarlab.com/rar/rarosx-5.5.0.tar.gz
npm config set registry http://registry.npm.taobao.org
npm install gulp-cli -g
npm install gulp -D
npm install --save-dev gulp-uglify gulp-jshint gulp-rename gulp-concat gulp-clean-css jshint
npm config delete registry
gulp
# js 解压缩
$PYTHON_BASE/bin/pip3 install jsbeautifier
$PYTHON_BASE/bin/js-beautify ~/ckeditor-releases-full-4.12.1/ckeditor.js


#php oauth
#./configure --with-php-config=$PHP_BASE/bin/php-config --with-libdir=$CURL_BASE --enable-oauth
https://github.com/greenplum-db/gpdb

star使用
http://blog.51cto.com/moerjinrong/2092371
http://man.linuxde.net/sar
https://linuxstory.org/generate-cpu-memory-io-report-sar-command/


openldap
wget ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release/openldap-2.4.46.tgz
tar zxf openldap-2.4.46.tgz
cd openldap-2.4.46
./configure --prefix=$OPT_BASE/openldap --enable-dynamic --enable-proctitle --with-tls --with-threads --with-cyrus-sasl --sysconfdir=$BASE_DIR/etc
make depend
make
make install

http://cubiq.org/iscroll-5
https://github.com/siqi0011/swoole_src_student/blob/master/Memory-Lock.md
https://www.cabalphp.com
验证码识别
https://github.com/tesseract-ocr/tesseract
https://github.com/thiagoalessio/tesseract-ocr-for-php
协程
http://www.laruence.com/2015/05/28/3038.html
https://segmentfault.com/a/1190000012457145
https://segmentfault.com/a/1190000010576658
https://www.jianshu.com/p/edef1cb7fee6
https://laravel-china.org/articles/1430/single-php-generator-complete-knowledge-generator-implementation-process
https://www.v2ex.com/t/289499
https://yaoguais.github.io/article/php/coroutine.html
https://chenqinghe.com/?p=214
http://nikic.github.io/2012/12/22/Cooperative-multitasking-using-coroutines-in-PHP.html
https://log.zvz.im/2016/07/01/PHP-Coroutine/
https://nikic.github.io/
https://nikic.github.io/2014/12/22/PHPs-new-hashtable-implementation.html
https://nikic.github.io/2014/02/18/Fast-request-routing-using-regular-expressions.html
https://nikic.github.io/2011/10/23/Improving-lexing-performance-in-PHP.html
https://nikic.github.io/2014/01/10/The-case-against-the-ifsetor-function.html
https://blog.ircmaxell.com/2012/07/what-generators-can-do-for-you.html




https://github.com/donnemartin/system-design-primer/blob/master/README-zh-Hans.md
https://dzone.com/articles/scalable-system-design
https://www.reactivedesignpatterns.com/categories.html



https://github.com/maxmind/MaxMind-DB-Writer-perl
https://metacpan.org/pod/MaxMind::DB::Writer::Tree
http://maxmind.github.io/MaxMind-DB/
https://www.cnblogs.com/yufengs/p/6606609.html

https://blog.csdn.net/openex/article/details/53487465


https://github.com/cuber/ngx_http_google_filter_module
https://github.com/arut/nginx-rtmp-module
https://github.com/yaoweibin/nginx_tcp_proxy_module

https://segmentfault.com/a/1190000009370316
http://blog.51cto.com/noican/1610117


https://pecl.php.net/package/fann
https://github.com/libfann/fann

http://lostphp.com/blog/863.html
https://blog.csdn.net/fengshuiyue/article/details/41446257
https://blog.csdn.net/liyuanbhu/article/details/51348227
https://www.helplib.com/GitHub/article_102389

https://github.com/sebastianbergmann/phpunit/releases

XDebug在github上的7年中已经有50个贡献者
phpdbg在4年半的时间里有一些贡献者（20-30），它已经在github上了
PHPUnit在8年半的时间里已经有了342个贡献者，它已经在github上了
phpstan在2年半的时间内已经有70个贡献者在github上了
[root@bogon xdebug-2.6.0]# find ./ -name "*.vim"
./contrib/xt.vim
[root@bogon xdebug-2.6.0]# vim contrib/
tracefile-analyser.php  xt.vim
[root@bogon xdebug-2.6.0]# ll xdebug.ini
-rw-r--r--. 1 orca orca 37775 1月  30 04:08 xdebug.ini

https://www.itcodemonkey.com/article/1913.html


https://reactnative.cn/docs/getting-started.html
https://github.com/facebook/react-native/releases
https://doc.react-china.org/
wget -c --content-disposition --no-check-certificate https://github.com/facebook/react-native/archive/v0.56.0.tar.gz


ab只能测试http，jmeter各种性能测试都可以
$PYTHON_BASE/bin/pip3 install --upgrade pip
$PYTHON_BASE/bin/pip3 install --upgrade tensorflow

vim hello_tf.go
go run hello_tf.go
go get github.com/tensorflow/tensorflow/tensorflow/go


wget https://github.com/bazelbuild/bazel/releases/download/0.16.1/bazel-0.16.1-installer-linux-x86_64.sh
chmod a+x bazel-0.16.1-installer-linux-x86_64.sh
sudo ./bazel-0.16.1-installer-linux-x86_64.sh

wget --content-disposition  https://github.com/tensorflow/tensorflow/archive/v1.10.0.tar.gz
tar zxf tensorflow-1.10.0.tar.gz
cd tensorflow-1.10.0
PYTHON_BIN_PATH="$PYTHON_BASE/bin/python3" ./configure

https://developer.baidu.com/resources/online/doc/
# 测试网站的tls
https://www.ssllabs.com/ssltest/analyze.html?d=www.mochoua.com


openssl ciphers  -V tls1_3 | column -t
openssl s_client -connect www.mochoua.com:443  -tls1_3
https://wiki.openssl.org/index.php/TLS1.3

https://zhuanlan.zhihu.com/p/38462399
https://phpopencv.org/
https://github.com/opencv/opencv/releases
https://github.com/hihozhou/php-opencv
https://github.com/php-opencv/php-opencv
https://github.com/pangudashu/php7-internal
https://github.com/php-opencv/php-opencv-examples
https://github.com/nagadomi/waifu2x

$PYTHON_BASE/bin/pip3 install --user numpy scipy matplotlib ipython jupyter pandas sympy nose


# remove color codes
# sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"
# sed "s,\x1B\[[0-9;]*[a-zA-Z],,g"
# sed -r "s:\x1B\[[0-9;]*[mK]::g"
# sed -r "s/\x1B\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g




#rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
#rpm -Uvh elrepo-release*rpm
rpm -Uvh http://repo.iotti.biz/CentOS/7/noarch/lux-release-7-1.noarch.rpm
yum install abiword

# 不更新，会报错
#abiword --help
#abiword: symbol lookup error: /lib64/libpango-1.0.so.0: undefined symbol: g_log_structured_standard
yum install glib2

# 中文字体
cp -r /usr/local/eyou/office/setup/truetype /usr/share/fonts/
time abiword -t pdf -o /tmp/5.pdf ~/doc/index1.docx

#系统监控
wget --content-disposition --no-check-certificate https://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Stable/4.0.5/zabbix-4.0.5.tar.gz/download


# https://www.linuxidc.com/Linux/2015-01/111364.htm
https://github.com/php-ai/php-ml


wget https://github.com/skvadrik/re2c/releases/download/1.2/re2c-1.2.tar.xz
tar Jxf re2c-1.2.tar.xz
cd re2c-1.2
./configure --prefix=/opt/re2c
make
make install
#wget https://github.com/skvadrik/re2c/releases/download/1.1.1/re2c-1.1.1.tar.gz
#tar zxf re2c-1.1.1.tar.gz
#cd re2c-1.1.1
#./autogen.sh
#./configure --prefix=/usr/local/
#version
#http://re2c.org/install/install.html

#wget https://swupdate.openvpn.org/community/releases/openvpn-2.4.8.tar.xz

#tar Jxf openvpn-2.4.8.tar.xz
#cd openvpn-2.4.8
#yum install lzo lzo-devel

#./configure --prefix=/usr/local/asdf/base1/opt/openvpn --enable-systemd
#make
#make install
#vim ./distro/systemd/openvpn-server@.service
#vim ./distro/systemd/openvpn-client@.service
#/usr/local/asdf/base1/opt/openvpn/lib/systemd/system/

wget --content-disposition --no-check-certificate https://github.com/facebookresearch/fastText/archive/v0.9.1.tar.gz
tar zxf fastText-0.9.1.tar.gz
cd fastText-0.9.1
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=/opt/asdf/base1/opt/fasttext ../
make
make install

wget --content-disposition --no-check-certificate https://github.com/YujiroTakahashi/fastText-php/archive/master.tar.gz
tar zxf fastText-php-master.tar.gz
cd fastText-php-master
/opt/asdf/base1/opt/php/bin/phpize
./configure --with-php-config=/opt/asdf/base1/opt/php/bin/php-config --enable-fasttext=/opt/asdf/base1/opt/fasttext
make

