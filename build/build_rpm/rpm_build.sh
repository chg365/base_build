#!/bin/sh

################################################################################
#
# mochoua.com & marketing system rpm package build
#
################################################################################

if [ `whoami` = "root" ];then
    echo "切勿以 root 的身份来创建 RPM。这个工作应该永远在一个没有特殊权限的户口内进行。以 root 的身份来创建 RPM 可能会损坏你的系统。" >&2
    exit 1;
fi

curr_dir=$(cd "$(dirname "$0")"; pwd);
EDDM_VERSION="1.0.9";

################################################################################
# Install open source library
################################################################################
chmod +x base_build.sh
./base_build.sh
if [ "$?" != "0" ];then
    echo 'base build faild.'
    exit 1;
fi

cd $curr_dir

################################################################################
# Set rpm build DIR
################################################################################
rpm_build_dir="$HOME/chg_base"
echo "%_topdir $rpm_build_dir/rpm" >> $HOME/.rpmmacros
#mkdir -p $HOME/chg_base/rpm
mkdir -p $rpm_build_dir/rpm/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
mkdir -p $rpm_build_dir/rpm/RPMS/{i386,x86_64}

################################################################################
# Copy spec to SPECS DIR
################################################################################
cp -f eddm_rpm.spec $rpm_build_dir/rpm/SPECS
sed -i "s/^Version: .*$/Version: $EDDM_VERSION/" $rpm_build_dir/rpm/SPECS/eddm_rpm.spec
#release=`uname -r`;
#release=${release%.*};
#release=${release##*.};
#sed -i "s/^Release: .*$/Release: rh$release/" $rpm_build_dir/rpm/SPECS/eddm_rpm.spec
release=`uname -r|sed 's/^.*\.el\([0-9]\{1,\}\)\(\..*\)\{0,\}$/\1/'`;
sed -i "s/^Release: .*$/Release: rhel$release/" $rpm_build_dir/rpm/SPECS/eddm_rpm.spec
if [ "$release" = "5" ];then
    sed -i 's/java-1\.8\.0-openjdk/java-1.7.0-openjdk/' $rpm_build_dir/rpm/SPECS/eddm_rpm.spec
fi

################################################################################
# Copy trunk.tar.gz to SOURCES DIR
################################################################################
cd ../
tmp_str=`pwd`;
tmp_str=${tmp_str##*/};
cd ../
is_exists_trunk=0;
if [ "$tmp_str" != "trunk" ];
then
    if [ -d trunk ];
	then
	    echo "trunk is exists!";
		exit 1;
	fi;
    mkdir trunk
    cp -rf $tmp_str/CMakeLists.txt  trunk/
    cp -rf $tmp_str/build trunk/
    cp -rf $tmp_str/src trunk/
    cp -rf $tmp_str/other trunk/
fi;

tar czf trunk.tar.gz trunk

if [ "$tmp_str" != "trunk" ];
then
	rm -rf trunk
fi;
cp -f trunk.tar.gz $HOME/chg_base/rpm/SOURCES

rm -rf trunk.tar.gz

################################################################################
# RPM build
################################################################################
cd $HOME/chg_base/rpm
which rpmbuild > /dev/null
if [ "$?" != "0" ];then
    sudo yum -y install rpm-build redhat-rpm-config
fi
if ! which rpmbuild 1>/dev/null 2>&1 ;then
    echo "没有安装rpmbuild!" >&2
    exit 1;
fi
#rpmbuild --showrc
rpmbuild -bb SPECS/eddm_rpm.spec

rm -rf $HOME/chg_base/rpm/SOURCES
rm -rf $HOME/chg_base/rpm/SPECS


################################################################################
# END
################################################################################
