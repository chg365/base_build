################################################################################
#
# chg base system RPM spec
#
################################################################################

################################################################################
# Header段
# 本段定义软件包的名称，版本号，以及变量
################################################################################
Name: chg-base
Group: Applications/Productivity
License: mochoua.com Commerical License

Version: 1.0.0
Release: rhel

Summary: chg base system
Vendor:  www.mochoua.com
Packager: mochoua.com
Url: http://www.mochoua.com

#Source: %{name}-%{version}.tar.gz
Source: trunk.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
Prefix: %{_prefix}
Prefix: %{_sysconfdir}
#BuildArch: noarch
Requires: libXext perl-WWW-Curl java-1.8.0-openjdk

%define userpath /usr/local/chg/base
%define debug_packages %{nil}
%define debug_package %{nil}

%description
Powered by mochoua.com rpm suite.

###############################################################################
# prep段
# 本段是准备段，用于嵌入spec的shell脚本，通常用于解压软件包。
###############################################################################
%prep
%setup -c

###############################################################################
# build段
# 本段是建立段，所要执行的命令为生成软件包服务，如cmake命令。
# 编译该软件包，shell脚本从软件包的子目录下运行。
###############################################################################
%build
mkdir -p trunk/build
cd trunk/build
cmake ..
make

###############################################################################
# install段
# 本段是在构建系统上安装软件包，为了最后能封装成rpm，需要将文件安装到虚拟目录。
###############################################################################
%install
install -d $RPM_BUILD_ROOT%{userpath}
cd trunk/build
make install DESTDIR=$RPM_BUILD_ROOT

cd ../other
tar zcf fonts.tar.gz fonts
cp fonts.tar.gz $RPM_BUILD_ROOT%{userpath}/setup/
rm fonts.tar.gz
tar zxf jodconverter_java_lib.tar.gz -C $RPM_BUILD_ROOT%{userpath}/lib/
cd ../build

cp -a %{userpath}/* $RPM_BUILD_ROOT%{userpath}

###############################################################################
# clean段
# 本段用于最后删除临时文件，构建完软件包后执行。
###############################################################################
%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf "$RPM_BUILD_ROOT"
rm -rf $RPM_BUILD_DIR/%{name}-%{version}

###############################################################################
# file段
# 本段是文件段，用于定义软件包所包含的文件。
# 分为三类：说明文档(doc)，配置文件(config)，执行程序。
###############################################################################
%files
%defattr(-,root,root) 
%{userpath}

###############################################################################
# pre段
# RPM安装前执行的脚本
###############################################################################
%pre

#find /opt/openoffice*/ -name soffice
if [ ! -f "/opt/openoffice4/program/soffice" ];then
	echo ""
	echo -e "[\033[0;31mopenoffice not install, Please install openoffice4 first, exit now!\033[0m]"
	echo ""
	exit 1;
fi

if [ -d %{userpath} ];then
	echo ""
	echo "[\033[0;31mchg base install dir '%{userpath}' exists, please remove it manually, exit now!\033[0m]"
	echo ""
	exit 1;
fi

###############################################################################
# post段
# RPM安装后执行的脚本
###############################################################################
%post
echo "Initializing..."
echo ""
echo -e "chg base Initialization: [\033[0;32mStart\033[0m]"

tar zxf %{userpath}/setup/fonts.tar.gz -C /opt/openoffice4/share/

if %{userpath}/setup/eddm_initialize.sh;then
	echo -e "chg base Initialization: [\033[0;32mDone\033[0m]"
	echo ""
else
	echo -e "chg base Initialization: [\033[0;31mFail\033[0m]"
    # test ""
fi

/bin/rm -rf %{userpath}/setup

ln -sf %{userpath}/sbin/chg_base /etc/init.d/chg_base

chkconfig --add chg_base
#chkconfig chg_base on

#定时执行程序
mkdir -p %{userpath}/data/tmp
crontab -l 2>/dev/null|grep -v 'eo_clean.php' > %{userpath}/data/tmp/clean_cron.tmp
echo "1 4 * * * %{userpath}/sbin/eo_clean.php >> %{userpath}/log/eo_clean.log 2>&1" >> %{userpath}/data/tmp/clean_cron.tmp
crontab %{userpath}/data/tmp/clean_cron.tmp
rm  -rf %{userpath}/data/tmp/clean_cron.tmp

###############################################################################
# preun段
# RPM卸载前执行的脚本
###############################################################################
%preun
echo "Stop chg base ..."

%{userpath}/sbin/chg_base stop
echo "Stop OK"

chkconfig --del chg_base
unlink /etc/rc.d/init.d/chg_base

#清理定时程序
crontab -l |grep -v 'eo_clean.php' > %{userpath}/data/tmp/clean_cron_invert.tmp
crontab %{userpath}/data/tmp/clean_cron_invert.tmp
rm -rf %{userpath}/data/tmp/clean_cron_invert.tmp

BACKUP_PATH=%{userpath}-backup-$(date +%%Y%%m%%d-%%H%%M%%S)
mv %{userpath} $BACKUP_PATH
echo "the old version '%{userpath}' backup to '$BACKUP_PATH'"

###############################################################################
# postun段
# RPM卸载后执行的脚本
###############################################################################
%postun


###############################################################################
# changelog段
# 本段是修改日志段，可以将每次的修改记录到发布的软件包中，用于查询。
# 格式：
#     * 星期 月 日 年 修改人电子信箱
#     多行数据
###############################################################################
%changelog
* Mon Jun 27 2017 cuihaiguang@gmail.com
- create Name
