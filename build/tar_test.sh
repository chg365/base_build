#!/bin/bash

dir="/root/chg_base/pkgs/"

type="z"
for FILE_NAME in `find $dir -mindepth 1 -maxdepth 1 -type f `;
do
    if [ "${FILE_NAME%%.tar.xz}" != "$FILE_NAME" ];then
        type="J"
    elif [ "${FILE_NAME%%.tar.Z}" != "$FILE_NAME" ];then
        type="j"
    elif [ "${FILE_NAME%%.tar.bz2}" != "$FILE_NAME" ];then
        type="j"
    elif [ "${FILE_NAME%%.tar.gz}" != "$FILE_NAME" ];then
        type="z"
    elif [ "${FILE_NAME%%.tgz}" != "$FILE_NAME" ];then
        type="z"
    elif [ "${FILE_NAME%%.tar.lz}" != "$FILE_NAME" ];then
        type="lzip"
    else
        echo "$FILE_NAME 未知文件类型"
        continue;
    fi

    echo "--------------------------"
    echo $FILE_NAME
    tar -$type -tf $FILE_NAME >/dev/null
    if [ "$?" != "0" ];then
        echo "$FILE_NAME 文件可能损坏."
    fi
    echo "=========================="
done;
