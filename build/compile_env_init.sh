#!/bin/bash
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#yum install gcc gcc-c++
#dependencies resolved
#
#================================================================================
#package              arch         version                  repository     size
#================================================================================
#installing:
#gcc                  x86_64       4.4.7-17.el6             base           10 m
#gcc-c++              x86_64       4.4.7-17.el6             base          4.7 M
#installing for dependencies:
#libstdc++-devel      x86_64       4.4.7-17.el6             base          1.6 M
#cloog-ppl            x86_64       0.15.7-1.2.el6           base           93 k
#cpp                  x86_64       4.4.7-17.el6             base          3.7 m
#glibc-devel          x86_64       2.12-1.192.el6           base          988 k
#glibc-headers        x86_64       2.12-1.192.el6           base          617 k
#kernel-headers       x86_64       2.6.32-642.1.1.el6       updates       4.4 m
#mpfr                 x86_64       2.4.1-6.el6              base          157 k
#ppl                  x86_64       0.10.2-11.el6            base          1.3 m
#updating for dependencies:
#libstdc++            x86_64       4.4.7-17.el6             base          295 k
#glibc                x86_64       2.12-1.192.el6           base          3.8 m
#glibc-common         x86_64       2.12-1.192.el6           base           14 m
#libgcc               x86_64       4.4.7-17.el6             base          103 k
#libgomp              x86_64       4.4.7-17.el6             base          134 k
#tzdata               noarch       2016d-1.el6              updates       451 k
#
#transaction summary
#================================================================================
#install       10 package(s)
#upgrade        6 package(s)
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#yum install gcc gcc-c++ autoconf m4 libarchive cmake m4 bison xz bzip2 re2c file

curr_dir=$(cd "$(dirname "$0")"; pwd);

base_define_file=$curr_dir/base_define.sh
base_function_file=$curr_dir/base_function.sh

if [ ! -f $base_define_file ]; then
    echo "can't find base_define.sh";
    exit;
fi

if [ ! -f $base_function_file ];then
    echo "can't find base_function.sh"
    exit;
fi

#line=`sed -n  '/^project_abbreviation=/p' $base_define_file`
#if [ `echo $line | wc -l` != 1 ]; then
#    echo "not have project_abbreviation variable.";
#    exit;
#fi
#eval $line;
. $base_define_file
. $base_function_file

#COMPILE_BASE=/usr/local/${project_abbreviation%%_*}/compile

BINUTILS_VERSION="2.26"
ISL_VERSION="0.16.1"
GMP_VERSION="6.1.1" #6.1.1
PPL_VERSION="0.12.1" # 1.1 1.2
CLOOG_VERSION="0.18.4"
MPC_VERSION="1.0.3"
MPFR_VERSION="3.1.4"
GCC_VERSION="6.1.0" # 4.6.4 4.9.3 5.4.0   6.1.0
BISON_VERSION="3.0.4"
AUTOMAKE_VERSION="1.15"
AUTOCONF_VERSION="2.69"
LIBTOOL_VERSION="2.4.6"
CMAKE_VERSION="3.5.2"
RE2C_VERSION="0.16"
M4_VERSION="1.4.17"
MAKE_VERSION="4.2.1"
PATCH_VERSION="2.7.5"
READLINE_VERSION="6.3"
GLIBC_VERSION="2.12.2" # 2.23
FLEX_VERSION="2.6.0"
PKGCONFIG_VERSION="0.29.1"
PYTHON_VERSION="3.5.1";

BINUTILS_FILE_NAME="binutils-${BINUTILS_VERSION}.tar.bz2"
ISL_FILE_NAME="isl-${ISL_VERSION}.tar.bz2"
GMP_FILE_NAME="gmp-${GMP_VERSION}.tar.lz" # xz
PPL_FILE_NAME="ppl-${PPL_VERSION}.tar.xz"
CLOOG_FILE_NAME="cloog-${CLOOG_VERSION}.tar.gz"
MPC_FILE_NAME="mpc-${MPC_VERSION}.tar.gz"
MPFR_FILE_NAME="mpfr-${MPFR_VERSION}.tar.xz"
GCC_FILE_NAME="gcc-$GCC_VERSION.tar.bz2"
BISON_FILE_NAME="bison-$BISON_VERSION.tar.xz" # xz
AUTOMAKE_FILE_NAME="automake-${AUTOMAKE_VERSION}.tar.xz"
AUTOCONF_FILE_NAME="autoconf-${AUTOCONF_VERSION}.tar.xz"
LIBTOOL_FILE_NAME="libtool-${LIBTOOL_VERSION}.tar.xz"
CMAKE_FILE_NAME="cmake-${CMAKE_VERSION}.tar.gz"
RE2C_FILE_NAME="re2c-${RE2C_VERSION}.tar.gz"
M4_FILE_NAME="m4-${M4_VERSION}.tar.xz"
MAKE_FILE_NAME="make-${MAKE_VERSION}.tar.bz2"
PATCH_FILE_NAME="patch-${PATCH_VERSION}.tar.xz"
READLINE_FILE_NAME="readline-${READLINE_VERSION}.tar.gz"
GLIBC_FILE_NAME="glibc-${GLIBC_VERSION}.tar.xz"
FLEX_FILE_NAME="flex-${FLEX_VERSION}.tar.xz"
PKGCONFIG_FILE_NAME="pkg-config-${PKGCONFIG_VERSION}.tar.gz"
PYTHON_FILE_NAME="Python-${PYTHON_VERSION}.tar.xz"

GCC_BASE=$COMPILE_BASE/gcc





# PKG_CONFIG_PATH处理 {{{
tmp_arr=( "/usr/lib64/pkgconfig" "/usr/share/pkgconfig" "/usr/lib/pkgconfig" "/usr/local/lib/pkgconfig" );
for i in ${tmp_arr[@]}; do
{
    if [ -d "$i" ];then
        PKG_CONFIG_PATH="$i:$PKG_CONFIG_PATH";
    fi
}
done

PKG_CONFIG_PATH=${PKG_CONFIG_PATH%:}
# }}}

export PATH="$COMPILE_BASE/bin:$PATH"

mkdir -p $HOME/$project_abbreviation/pkgs
cd $HOME/$project_abbreviation/pkgs

wget_fail=0;
wget_library
######################################################
#if [ -d $COMPILE_BASE ]; then
#    echo "The install dir '$COMPILE_BASE' exists, please remove it, exit now"
#    test ""
#    exit;
#fi

sudo mkdir -p $COMPILE_BASE

sudo chown -R `whoami` $COMPILE_BASE

which xz > /dev/null
if [ "$?" != "0" ]; then
    yum install -y xz
fi

which bzip2 > /dev/null
if [ "$?" != "0" ]; then
    yum install -y bzip2
fi

which lzip > /dev/null
if [ "$?" != "0" ]; then
    yum install -y lzip
fi

which file > /dev/null
if [ "$?" != "0" ]; then
    yum install -y file
fi

################################################################################
# Install gcc
################################################################################
# {{{ function compile_gmp()
function compile_gmp()
{
    GMP_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE \
                --enable-cxx
    "

    compile "gmp" "$GMP_FILE_NAME" "gmp-$GMP_VERSION" "GMP_CONFIGURE"
}
# }}}
# {{{ function compile_isl()
function compile_isl()
{
    ISL_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE --with-gmp-prefix=$COMPILE_BASE
    "
    # --with-gmp=build 
    # --with-gmp-exec-prefix= --with-gmp-builddir=

    compile "isl" "$ISL_FILE_NAME" "isl-$ISL_VERSION" "ISL_CONFIGURE"
}
# }}}
# {{{ function compile_ppl()
function compile_ppl()
{
    # 自已编译的版本好像太新不行
    # yum install gmp gmp-devel
    PPL_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE
    "
    # --with-gmp=$COMPILE_BASE
    # --with-mlgmp=

    compile "ppl" "$PPL_FILE_NAME" "ppl-$PPL_VERSION" "PPL_CONFIGURE"
}
# }}}
# {{{ function compile_cloog()
function compile_cloog()
{
    CLOOG_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE --with-isl-prefix=$COMPILE_BASE --with-gmp-prefix=$COMPILE_BASE
    "
    # --with-isl=no|system|build|bundled --with-gmp=system|build 
    # --with-osl-prefix= --with-osl=no|system|build|bundled

    compile "cloog" "$CLOOG_FILE_NAME" "cloog-$CLOOG_VERSION" "CLOOG_CONFIGURE"
}
# }}}
# {{{ function compile_mpfr()
function compile_mpfr()
{
    MPFR_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE --with-gmp=$COMPILE_BASE
    "
    compile "mpfr" "$MPFR_FILE_NAME" "mpfr-$MPFR_VERSION" "MPFR_CONFIGURE"
}
# }}}
# {{{ function compile_mpc()
function compile_mpc()
{
    MPC_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE --with-mpfr=$COMPILE_BASE --with-gmp=$COMPILE_BASE
    "
    compile "mpc" "$MPC_FILE_NAME" "mpc-$MPC_VERSION" "MPC_CONFIGURE"
}
# }}}
# {{{ function compile_binutils()
function compile_binutils()
{
    BINUTILS_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE \
                --with-mpc=$COMPILE_BASE --with-gmp=$COMPILE_BASE --with-mpfr=$COMPILE_BASE --with-isl=$COMPILE_BASE
    "

    compile "binutils" "$BINUTILS_FILE_NAME" "binutils-$BINUTILS_VERSION" "BINUTILS_CONFIGURE"
}
# }}}
# {{{ function compile_cmake()
function compile_cmake()
{
    CMAKE_CONFIGURE="
    ./bootstrap --prefix=$COMPILE_BASE
    "
    compile "cmake" "$CMAKE_FILE_NAME" "cmake-$CMAKE_VERSION" "CMAKE_CONFIGURE"
}
# }}}
# {{{ function compile_bison()
function compile_bison()
{
    BISON_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE
    "
#  --with-libpth-prefix= --with-libiconv-prefix= --with-libintl-prefix=
    compile "bison" "$BISON_FILE_NAME" "bison-$BISON_VERSION" "BISON_CONFIGURE"
}
# }}}
# {{{ function compile_automake()
function compile_automake()
{
    AUTOMAKE_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE
    "
    compile "automake" "$AUTOMAKE_FILE_NAME" "automake-$AUTOMAKE_VERSION" "AUTOMAKE_CONFIGURE"
}
# }}}
# {{{ function compile_autoconf()
function compile_autoconf()
{
    AUTOCONF_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE
    "
    # --with-lispdir

    compile "autoconf" "$AUTOCONF_FILE_NAME" "autoconf-$AUTOCONF_VERSION" "AUTOCONF_CONFIGURE"
}
# }}}
# {{{ function compile_libtool()
function compile_libtool()
{
    LIBTOOL_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE
    "
    compile "libtool" "$LIBTOOL_FILE_NAME" "libtool-$LIBTOOL_VERSION" "LIBTOOL_CONFIGURE"
}
# }}}
# {{{ function compile_re2c()
function compile_re2c()
{
    RE2C_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE
    "
    compile "re2c" "$RE2C_FILE_NAME" "re2c-$RE2C_VERSION" "RE2C_CONFIGURE"
}
# }}}
# {{{ function compile_m4()
function compile_m4()
{
    M4_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE
    "
    # --with-libsigsegv-prefix= --with-libpth-prefix=

    compile "m4" "$M4_FILE_NAME" "m4-$M4_VERSION" "M4_CONFIGURE"
}
# }}}
# {{{ function compile_make()
function compile_make()
{
    MAKE_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE
    "
    # --with-libiconv-prefix --with-libintl-prefix

    compile "make" "$MAKE_FILE_NAME" "make-$MAKE_VERSION" "MAKE_CONFIGURE"
}
# }}}
# {{{ function compile_pkgconfig()
function compile_pkgconfig()
{
    PKGCONFIG_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE --with-internal-glib
    "
    compile "pkgconfig" "$PKGCONFIG_FILE_NAME" "pkg-config-$PKGCONFIG_VERSION" "PKGCONFIG_CONFIGURE"
}
# }}}
# {{{ function compile_patch()
function compile_patch()
{
    PATCH_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE
    "
    compile "patch" "$PATCH_FILE_NAME" "patch-$PATCH_VERSION" "PATCH_CONFIGURE"
}
# }}}
# {{{ function compile_readline()
function compile_readline()
{
    READLINE_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE
    "
    # --with-curses --with-purify --enable-multibyte

    compile "readline" "$READLINE_FILE_NAME" "readline-$READLINE_VERSION" "READLINE_CONFIGURE"
}
# }}}
# {{{ function compile_glibc()
function compile_glibc()
{
#    GLIBC_CONFIGURE="
#    mkdir ../glibc_install; cd ../glibc_install;
#    ./configure --prefix=$COMPILE_BASE
#    "
#    # --with-gd=
#
#    compile "glibc" "$GLIBC_FILE_NAME" "glibc-$GLIBC_VERSION" "GLIBC_CONFIGURE"
    echo_build_start "glibc"
    mkdir glibc_${GLIBC_VERSION}_install

    decompress $GLIBC_FILE_NAME
    if [ "$?" != "0" ];then
        return 1;
    fi

    cd glibc_${GLIBC_VERSION}_install

    ../glibc-${GLIBC_VERSION}/configure --prefix=$COMPILE_BASE/glib

    make_run "$?/glibc"
    if [ "$?" != "0" ];then
        exit 1;
    fi


    cd ..
    /bin/rm -rf glibc-$GLIBC_VERSION
    /bin/rm -rf glibc_${GLIBC_VERSION}_install

}
# }}}
# {{{ function compile_flex()
function compile_flex()
{
    FLEX_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE
    "
    # --with-libiconv-prefix  --with-libintl-prefix

    compile "flex" "$FLEX_FILE_NAME" "flex-$FLEX_VERSION" "FLEX_CONFIGURE"
}
# }}}
# {{{ function compile_gcc()
function compile_gcc()
{
    # 4.6.4 用系统的
    # yum install gmp gmp-devel ppl-devel cloog-ppl libmpc libmpc-devel mpfr mpfr-devel libisl libisl-devel
    # yum install glibc.i686 glibc.x86_64 glibc-devel.i686 glibc-devel.x86_64
    # yum install zip
# ./configure --prefix=/usr/local/chg/compile/gcc

    GCC_CONFIGURE="
    ./configure --prefix=$GCC_BASE --with-mpc=$COMPILE_BASE --with-gmp=$COMPILE_BASE --with-mpfr=$COMPILE_BASE \
                --with-isl=$COMPILE_BASE \
                --disable-multilib
    "
    echo $GCC_CONFIGURE;
    exit;
#$([ $GCC_VERSION = "4.9.3" ] && echo " --with-isl=$COMPILE_BASE" ) \
#                $([ $GCC_VERSION = "5.4.0" ] && echo " --with-isl=$COMPILE_BASE" ) \
#                $([ $GCC_VERSION = "6.1.0" ] && echo " --with-isl=$COMPILE_BASE" ) \
# --disable-multilib
# 因为报错：configure: error: I suspect your system does not have 32-bit development libraries (libc and headers). If you have them, rerun configure with --enable-multilib. If you do not have them, and want to build a 64-bit-only compiler, rerun configure with --disable-multilib.

    compile "gcc" "$GCC_FILE_NAME" "gcc-$GCC_VERSION" "GCC_CONFIGURE"
}
# }}}
# {{{ function compile_python()
function compile_python()
{
    PYTHON_CONFIGURE="
    ./configure --prefix=$COMPILE_BASE
    "
    compile "python" "$PYTHON_FILE_NAME" "Python-$PYTHON_VERSION" "PYTHON_CONFIGURE"
}
# }}}
#compile_gmp
#compile_isl
#compile_ppl  #不用了，用系统的
#compile_cloog #不用了，用系统的
#compile_mpfr
#compile_mpc
#compile_binutils
#compile_bison
#compile_m4
#compile_autoconf
#compile_automake
#compile_libtool
#compile_re2c
#compile_cmake
#compile_make
#compile_patch
#compile_readline
#compile_flex
#compile_pkgconfig
#compile_gcc
#compile_python
export PATH="$GCC_BASE/bin:$COMPILE_BASE/bin:$PATH"
compile_glibc
exit;
#编译需要6G空间
#yum install zip antlr
#yum install glibc.i686 glibc-devel.i686
#yum install  glibc glibc-devel
#./configure
#make




exit;
./config --prefix=$OPENSSL_BASE threads shared -fPIC
# -darwin-i386-cc

make_run "$?/openssl"
if [ "$?" != "0" ];then
    exit 1;
fi

cd ..

/bin/rm -rf openssl-$OPENSSL_VERSION

################################################################################
# Install 
################################################################################
