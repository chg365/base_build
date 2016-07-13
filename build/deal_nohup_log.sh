#!/bin/bash

curr_dir=$(cd "$(dirname "$0")"; pwd);
base_build_file=`find $curr_dir -type f -name base_build.sh`;
if [ $base_build_file = "" ];then
	echo '查找base_build.sh文件失败';
	exit
fi

project_abbreviation=`sed -n 's/^ \{0,\}project_abbreviation=["'']\{0,1\}\([^"'']\{1,\}\)["'']\{0,1\} \{0,\};\{0,\}$/\1/p' $base_build_file`;
BASE_DIR=`sed -n 's/^ \{0,\}BASE_DIR=["'']\{0,1\}\([^"'']\{1,\}\)["'']\{0,1\} \{0,\};\{0,\}$/\1/p' $base_build_file`;
BASE_DIR=`eval echo -n $BASE_DIR`;
CONTRIB_BASE=`sed -n 's/^ \{0,\}CONTRIB_BASE=["'']\{0,1\}\([^"'']\{1,\}\)["'']\{0,1\} \{0,\};\{0,\}$/\1/p' $base_build_file`;
CONTRIB_BASE=`eval echo -n $CONTRIB_BASE`;
OPT_BASE=`sed -n 's/^ \{0,\}OPT_BASE=["'']\{0,1\}\([^"'']\{1,\}\)["'']\{0,1\} \{0,\};\{0,\}$/\1/p' $base_build_file`;
OPT_BASE=`eval echo -n $OPT_BASE`;

if [ "$1" = "" ] || [ ! -f "$1" ]; then
    echo "用法: $0 base_build.sh执行的日志文件";
    exit;
fi
if [ ! -f "$1.bak" ]; then
    cp $1 $1.bak;
fi
# 多行内容处理
sed -i '/\\$/,/[^\\]$/d' $1
#sed -i '/^rm .\{1,\}\\$/,/[^\\]$/d' $1
#sed -i '/^if.\{1,\}\\$/,/[^\\]$/d' $1
#sed -i '/^\[ .\{1,\}\\$/,/[^\\]$/d' $1
#sed -i '/^sed .\{1,\}\\$/,/[^\\]$/d' $1
#sed -i '/^rm .\{1,\}\\$/,/[^\\]$/d' $1

sed -i '/^-- /d' $1
#sed -i '/^-- Looking for /d' $1
#sed -i '/^-- Installing: /d' $1

sed -i '/^\[ \{0,2\}[0-9]\{1,3\}%\] /d' $1
#sed -i '/^\[ [0-9]\{1,2\}%\] Built target /d' $1
#sed -i '/^\[ \{0,2\}[0-9]\{1,2\}%\] Built /d' $1
#sed -i '/^\[ \{0,2\}[0-9]\{1,2\}%\] Built/d' $1
#sed -i '/^\[ \{0,2\}[0-9]\{1,2\}%\] Buil/d' $1
#sed -i '/^\[ \{0,2\}[0-9]\{1,3\}%\] Buil/d' $1

array=( "checking" "creating" "Checking" "Linking" "installing" "Making" "making" "configure:" "ar" "libtool:" "test" "cp" "chmod" "mv" "make" "rm" "ln" "cd" "sed" "ranlib" "if" "mkdir" "m4" "gawk" )
for i in ${array[@]};
do
{
	sed -i "/^$i /d" $1;
}
done

sed -i '/^config\.status: /d' $1
sed -i '/^created directory /d' $1
sed -i '/^ \{0,1\}gcc /d' $1
sed -i '/^Scanning dependencies of target /d' $1
sed -i '/^ \{0,1\}cc /d' $1
sed -i '/^make\[[1-7]\]: /d' $1
sed -i '/^[a-z0-9._-]\{1,\}\.[ch]\{1\} => [a-z0-9._\/-]\{1,\}\.[ch]\{1\}/d' $1
sed -i '/^[A-Za-z0-9._-]\{1,\}\.[3]\{1\} => [A-Za-z0-9._\/-]\{1,\}\.[3]\{1\}/d' $1


sed -i "/^$(which ranlib|sed 's/\//\\\//g') /d" $1
sed -i "/^$(which perl|sed 's/\//\\\//g') /d" $1
sed -i "/^ \{0,1\}$(which install|sed 's/\//\\\//g') /d" $1
sed -i "/^ \{0,1\}$(which mkdir|sed 's/\//\\\//g') /d" $1
sed -i "/^ \{0,2\}$(which sh|sed 's/\//\\\//g') /d" $1
libtool_cmd=`find $CONTRIB_BASE -name libtool -type f`
if [ $libtool_cmd != "" ];then
    sed -i "/^ \{0,1\}$(echo -n $libtool_cmd|sed 's/\//\\\//g') /d" $1
fi


sed -i '/^(.\{1,\})$/d' $1
sed -i '/^  CC /d' $1
sed -i '/^  CCLD /d' $1
sed -i '/^  CXX  /d' $1
sed -i '/^  CXXLD  /d' $1
sed -i '/^  GEN  /d' $1
sed -i '/^\.\/builds\/unix\/libtool/d' $1
sed -i '/^apr\(-util\)\{0,1\}-[A-Za-z0-9._\/-]\{1,\}$/d' $1
#sed -i '/^apr-.\{1,\}\.[ch]$/d' $1
