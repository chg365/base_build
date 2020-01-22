#!/bin/sh

curr_dir=$(cd "$(dirname "$0")"; pwd);
#otool -L

which brew > /dev/null 2>&1
if [ $? -ne 0 ];then
    echo "缺少工具brew." >&2
    exit 1;
fi

# {{{ brew install
if [ ! -f $HOME/.chg_base_compile_env ]; then
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

    touch $HOME/.chg_base_compile_env
fi
# }}}
