#!/bin/sh


curr_dir=$(cd "$(dirname "$0")"; pwd);
#dnf

# {{{ yum install
if [ ! -f $HOME/.chg_base_compile_env ]; then

    sudo yum install -y wget vim git lrzsz

    sudo yum install -y tar xz       bzip2       unzip \
                            xz-devel bzip2-devel \

    sudo yum install -y m4 autoconf cmake make gcc gcc-c++ automake libtool \

    #语言包
    #sudo yum install -y langpacks-en
    #sudo yum install -y langpacks-zh_CN
    #rpm -qa|grep lang

    #openssl 帮助文档 少命令 pod2html
    #sudo yum install -y perl

    # centos8
    sudo yum install pkgconf-pkg-config
    # centos7
    sudo yum install pkgconfig

    sudo yum install bison

    sudo yum install -y texinfo ncurses-devel ncurses byacc \
                        libtool-ltdl-devel coreutils nasm
    sudo yum install -y curl nss libacl libacl-devel \
                        libattr libattr-devel gperf pam pam-devel krb5-devel krb5-libs \
                        libmount libmount-devel \
                        gdbm-devel

    sudo yum install -y itstool patch # fontconfig 2.12.91

    sudo yum  install -y libicu       harfbuzz       boost-program-options \

    sudo yum  install -y libicu-devel harfbuzz-devel boost-devel\

    #postgresql
    sudo yum install -y uuid \
                        uuid-devel

    sudo yum install -y libacl       libattr       mariadb-libs  readline       ncurses \
                        libuuid        cyrus-sasl cyrus-sasl-lib  pam       popt \
                        libacl-devel libattr-devel mariadb-devel readline-devel ncurses-devel \
                        libuuid-devel  cyrus-sasl-devel           pam-devel popt-devel

    sudo yum install -y file-devel \
                        gperf \
                        uuid \
                        uuid-devel \
                        re2c \
    # centos8
    sudo dnf --enablerepo=PowerTools install file-devel \
                                             gperf \
                                             xcb-proto \
                                             uuid \
                                             uuid-devel \
                                             re2c \
                                             libmemcached \
                                             libmemcached-devel \
                                             libmemcached-libs \


    # Python
    sudo yum install -y expat       libffi       tcl       tk \
                        expat-devel libffi-devel tcl-devel tk-devel

    #sudo yum install -y zlib-devel
    sudo yum install -y gettext-devel meson mariadb-devel

    tmp_str=`uname -r|awk -F. '{print $(NF-1);}'|sed -n 's/el//p'`; # 6 7 8
    if echo $tmp_str |grep -q '^[0-9]\{1,\}$'  ;then
        if [ "$tmp_str" -qt 6 ] ;then
            sudo yum -y install systemd-devel
        fi
    fi

    touch $HOME/.chg_base_compile_env
fi
# }}}
exit;

# IP库下载不了了



#shopt | grep huponexit
#disown
# screen tmux
# autoconf，automake，autopoint，pkg-config
#wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo

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

#wget https://www.rarlab.com/rar/rarlinux-x64-5.5.0.tar.gz
#wget https://www.rarlab.com/rar/rarosx-5.5.0.tar.gz

# js css 压缩
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


#wget --no-check-certificate --content-disposition https://github.com/swig/swig/archive/rel-3.0.12.tar.gz
#tar zxf swig-rel-3.0.12.tar.gz
#cd swig-rel-3.0.12
#./autogen.sh
#./configure --prefix=$OPT_BASE/swig \
#            --with-pcre-prefix=$PCRE_BASE \
#            --with-php=$PHP_BASE/bin/php \
#            --with-python3=$PYTHON_BASE/bin/python3.6
#make
#make install

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

