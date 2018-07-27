#!/bin/bash

curr_dir=$(cd "$(dirname "$0")"; pwd);
base_define_file=`find $curr_dir -type f -name base_define.sh`;
if [ $base_define_file = "" ];then
	echo '查找base_define.sh文件失败';
	exit
fi

project_abbreviation=`sed -n 's/^ \{0,\}project_abbreviation=["'']\{0,1\}\([^"'']\{1,\}\)["'']\{0,1\} \{0,\};\{0,\}$/\1/p' $base_define_file`;
BASE_DIR=`sed -n 's/^ \{0,\}BASE_DIR=["'']\{0,1\}\([^"'']\{1,\}\)["'']\{0,1\} \{0,\};\{0,\}$/\1/p' $base_define_file`;
BASE_DIR=`eval echo -n $BASE_DIR`;
CONTRIB_BASE=`sed -n 's/^ \{0,\}CONTRIB_BASE=["'']\{0,1\}\([^"'']\{1,\}\)["'']\{0,1\} \{0,\};\{0,\}$/\1/p' $base_define_file`;
CONTRIB_BASE=`eval echo -n $CONTRIB_BASE`;
OPT_BASE=`sed -n 's/^ \{0,\}OPT_BASE=["'']\{0,1\}\([^"'']\{1,\}\)["'']\{0,1\} \{0,\};\{0,\}$/\1/p' $base_define_file`;
OPT_BASE=`eval echo -n $OPT_BASE`;

if [ "$1" = "" ] || [ ! -f "$1" ]; then
    echo "用法: $0 base_build.sh执行的日志文件";
    exit;
fi
if [ ! -f "$1.bak" ]; then
    cp $1 $1.bak;
fi
PID=$$

sed -i.bak.$PID '/^[.+*]\{1,\}$/d' $1
sed -i.bak.$PID '/^( echo .\{1,\} ) >objfiles.txt$/d' $1

# 多行内容处理
sed -i.bak.$PID '/\\$/,/[^\\]$/d' $1
#sed -i.bak.$PID '/^rm .\{1,\}\\$/,/[^\\]$/d' $1
#sed -i.bak.$PID '/^if.\{1,\}\\$/,/[^\\]$/d' $1
#sed -i.bak.$PID '/^\[ .\{1,\}\\$/,/[^\\]$/d' $1
#sed -i.bak.$PID '/^sed .\{1,\}\\$/,/[^\\]$/d' $1
#sed -i.bak.$PID '/^rm .\{1,\}\\$/,/[^\\]$/d' $1

sed -i.bak.$PID '/^-- /d' $1
sed -i.bak.$PID '/^common.copy /d' $1
sed -i.bak.$PID '/^common.mkdir /d' $1
sed -i.bak.$PID '/^gcc.compile.c++ .\{1,\}\.o$/d' $1
sed -i.bak.$PID '/^\.\{3\}.\{1,\}\.\{3\}$/d' $1
#sed -i.bak.$PID '/^-- Looking for /d' $1
#sed -i.bak.$PID '/^-- Installing: /d' $1

sed -i.bak.$PID '/^\[ \{0,2\}[0-9]\{1,3\}%\] /d' $1
#sed -i.bak.$PID '/^\[ [0-9]\{1,2\}%\] Built target /d' $1
#sed -i.bak.$PID '/^\[ \{0,2\}[0-9]\{1,2\}%\] Built /d' $1
#sed -i.bak.$PID '/^\[ \{0,2\}[0-9]\{1,2\}%\] Built/d' $1
#sed -i.bak.$PID '/^\[ \{0,2\}[0-9]\{1,2\}%\] Buil/d' $1
#sed -i.bak.$PID '/^\[ \{0,2\}[0-9]\{1,3\}%\] Buil/d' $1

array=( "checking" "creating" "Checking" "Linking" "installing" "Making" "making" "configure:" "ar" "libtool:" "test" "cp" "chmod" "mv" "make" "rm" "ln" "cd" "sed" "ranlib" "if" "mkdir" "m4" "gawk" )
for i in ${array[@]};
do
{
	sed -i.bak.$PID "/^$i /d" $1;
}
done

sed -i.bak.$PID '/^config\.status: /d' $1
sed -i.bak.$PID '/^created directory /d' $1
sed -i.bak.$PID '/^ \{0,1\}gcc /d' $1
sed -i.bak.$PID '/^Scanning dependencies of target /d' $1
sed -i.bak.$PID '/^ \{0,1\}cc /d' $1
sed -i.bak.$PID '/^make\[[1-7]\]: /d' $1
sed -i.bak.$PID '/^[a-z0-9._-]\{1,\}\.[ch]\{1\} => [a-z0-9._\/-]\{1,\}\.[ch]\{1\}/d' $1
sed -i.bak.$PID '/^[A-Za-z0-9._-]\{1,\}\.[3]\{1\} => [A-Za-z0-9._\/-]\{1,\}\.[3]\{1\}/d' $1


sed -i.bak.$PID "/^[^:]\{1,\}$(which ranlib|sed 's/\//\\\//g') /d" $1
sed -i.bak.$PID "/^$(which perl|sed 's/\//\\\//g') /d" $1
sed -i.bak.$PID "/^ \{0,1\}$(which install|sed 's/\//\\\//g') /d" $1
sed -i.bak.$PID "/^ \{0,1\}$(which mkdir|sed 's/\//\\\//g') /d" $1
sed -i.bak.$PID "/^ \{0,2\}$(which sh|sed 's/\//\\\//g') /d" $1
sed -i.bak.$PID "/^ \{0,2\}$(echo $BASE_DIR|sed 's/\//\\\//g')[^:]\{1,\}$/d" $1
sed -i.bak.$PID "/^ \{0,2\}$(echo $HOME/$project_abbreviation/pkgs|sed 's/\//\\\//g')$/d" $1
libtool_cmd=`find $CONTRIB_BASE -name libtool -type f`
if [ "$libtool_cmd" != "" ];then
    sed -i.bak.$PID "/^ \{0,1\}$(echo -n $libtool_cmd|sed 's/\//\\\//g') /d" $1
fi


sed -i.bak.$PID '/^(.\{1,\})$/d' $1
sed -i.bak.$PID '/^  CC /d' $1
sed -i.bak.$PID '/^CC="cc"/d' $1
sed -i.bak.$PID '/^CC="gcc" /d' $1
sed -i.bak.$PID '/^LD_LIBRARY_PATH=/d' $1
sed -i.bak.$PID '/^ \{0,\}\/bin\/sh /d' $1
sed -i.bak.$PID '/^autoreconf: /d' $1
sed -i.bak.$PID '/^configure.ac:/d' $1
sed -i.bak.$PID '/^[a-z0-9A-Z.\/]\{0,\}libtool /d' $1
sed -i.bak.$PID '/^[a-z0-9A-Z.\/]\{0,\}libtoolize: /d' $1
sed -i.bak.$PID '/^ \{0,1\}g++ /d' $1
sed -i.bak.$PID '/^clang++ /d' $1
sed -i.bak.$PID '/^\(\/.\{1,\}\)\{0,1\}\/usr\/bin\/make/d' $1
sed -i.bak.$PID '/^pkgdata:/d' $1
sed -i.bak.$PID '/^Building shared library/d' $1
sed -i.bak.$PID '/^+ /d' $1
#sed -i.bak.$PID '/^In file included from .\{1,\}[^,:]$/d' $1
sed -i.bak.$PID '/^ \{1,\}clang+\{0,\}.\{1,\}\.\{3\}/d' $1
#sed -i.bak.$PID '/^install .\{1,\}.h -> .\{1,\}.h/d' $1
sed -i.bak.$PID '/^  CCLD /d' $1
sed -i.bak.$PID '/^  CXX  /d' $1
sed -i.bak.$PID '/^  CXXLD  /d' $1
sed -i.bak.$PID '/^  GEN  /d' $1
sed -i.bak.$PID '/^\.\/builds\/unix\/libtool/d' $1
sed -i.bak.$PID '/^ldconfig: file /d' $1
sed -i.bak.$PID '/^[A-Z0-9 _]\{1,\}=/d' $1
sed -i.bak.$PID '/`cat /d' $1
sed -i.bak.$PID '/^echo /d' $1
sed -i.bak.$PID '/^tools\/an /d' $1
sed -i.bak.$PID '/ yes$/d' $1
sed -i.bak.$PID '/ no$/d' $1
sed -i.bak.$PID '/\[default\]/d' $1
sed -i.bak.$PID "/^[ \t]\{1,\}\*[ \t]\{1,\}/d" $1
sed -i.bak.$PID '/^Installing shared extensions:/d' $1
sed -i.bak.$PID "/^Don't forget to run 'make test'./d" $1
sed -i.bak.$PID '/^Build complete./d' $1
sed -i.bak.$PID '/^Configuring for:/,/^configure command:/d' $1
sed -i.bak.$PID '/^`--/,/^$/d' $1
sed -i.bak.$PID '/make\[[0-9]\{1,\}\]:/d' $1
sed -i.bak.$PID "/[\t ]\{1,\}g++[\t ]\{1,\}...[\t ]\{1,\}/d" $1
sed -i.bak.$PID "/[\t ]\{1,\}gcc[\t ]\{1,\}...[\t ]\{1,\}/d" $1
sed -i.bak.$PID "/ \{0,\}(deps)[ \t]\{1,\}/d" $1
sed -i.bak.$PID '/^PATH="$PATH:\/sbin" ldconfig /d' $1
sed -i.bak.$PID '/^appending configuration tag/d' $1
sed -i.bak.$PID '/^apr\(-util\)\{0,1\}-[A-Za-z0-9._\/-]\{1,\}$/d' $1
sed -i.bak.$PID '/^Libraries have been installed in:$/,/^more information, such as the ld(1) and ld.so(8) manual pages.$/d' $1
#sed -i.bak.$PID '/^apr-.\{1,\}\.[ch]$/d' $1
sed -i.bak.$PID '/.\{1,\} -> .\{1,\}/d' $1
sed -i.bak.$PID '/: installing/d' $1
sed -i.bak.$PID '/\. : /d' $1
sed -i.bak.$PID '/^-\{1,\}$/d' $1
sed -i.bak.$PID '/^*\{1,3\} /d' $1
sed -i.bak.$PID '/^DOCMAN3 /d' $1
sed -i.bak.$PID '/\[34mCC/d' $1
sed -i.bak.$PID '/\[32;/d' $1
sed -i.bak.$PID '/\[34;/d' $1
sed -i.bak.$PID '/^Copying file /d' $1
sed -i.bak.$PID '/[\t]yes$/d' $1
sed -i.bak.$PID '/[\t]no$/d' $1
sed -i.bak.$PID '/^  setting /d' $1
sed -i.bak.$PID '/^  adding /d' $1
sed -i.bak.$PID '/^Generate /d' $1
sed -i.bak.$PID '/^copying selected object files to/d' $1
sed -i.bak.$PID '/\[1m  +-/,/\[m/d' $1
sed -i.bak.$PID '/^Installing /d' $1
sed -i.bak.$PID '/^cat /d' $1
sed -i.bak.$PID '/^Building /d' $1
sed -i.bak.$PID '/^sh -c /d' $1
sed -i.bak.$PID '/apinames/d' $1
sed -i.bak.$PID '/[\t]false$/d' $1
sed -i.bak.$PID '/[\t]true$/d' $1
sed -i.bak.$PID '/^Install /d' $1
sed -i.bak.$PID '/^  CPPAS    /d' $1
sed -i.bak.$PID '/^`echo \/bin\/sh/d' $1

sed -i.bak.$PID '/^$/{n;/^$/d}' $1

rm -rf $1.bak.$PID
