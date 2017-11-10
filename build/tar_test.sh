#!/bin/bash

dir="${HOME}/chg_base/pkgs/"

type="z"
for FILE_NAME in `find $dir -mindepth 1 -maxdepth 1 -type f `;
do
    if [ "${FILE_NAME%%.tar.xz}" != "$FILE_NAME" ];then
        type="J"
    elif [ "${FILE_NAME%%.txz}" != "$FILE_NAME" ];then
        type="J"
    elif [ "${FILE_NAME%%.tar.Z}" != "$FILE_NAME" ];then
        type="j"
    elif [ "${FILE_NAME%%.tar.bz2}" != "$FILE_NAME" ];then
        type="j"
    elif [ "${FILE_NAME%%.tar.gz}" != "$FILE_NAME" ];then
        type="z"
    elif [ "${FILE_NAME%%.gz}" != "$FILE_NAME" ];then
        gunzip -t $FILE_NAME >/dev/null 2>&1
        if [ "$?" != "0" ];then
            echo "${FILE_NAME}文件可能已经损坏!" >&2
        fi
        continue;
    elif [ "${FILE_NAME%%.tgz}" != "$FILE_NAME" ];then
        type="z"
    elif [ "${FILE_NAME%%.tar.lz}" != "$FILE_NAME" ];then
        type="lzip"
    elif [ "${FILE_NAME%%.zip}" != "$FILE_NAME" ];then
        unzip -qqt $FILE_NAME >/dev/null 2>&1
        if [ "$?" != "0" ];then
            echo "${FILE_NAME} 文件可能已经损坏." >&2
        fi
        continue;
    elif [ "${FILE_NAME%%.dmg}" != "$FILE_NAME" ];then
        #hdiutil attach $FILE_NAME  > /dev/null
        hdiutil imageinfo $FILE_NAME  > /dev/null
        if [ "$?" != "0" ];then
            echo "${FILE_NAME} 文件可能已经损坏." >&2
        fi
        #hdiutil detach /Volumes/${FILE_NAME%.*} >/dev/null
        continue
#elif [ "${FILE_NAME%%.rar}" != "$FILE_NAME" ];then
#        # unrar e $FILE_NAME
#        #unrar t $FILE_NAME
#        if [ "$?" != "0" ];then
#            echo "${FILE_NAME} 文件可能已经损坏." >&2
#        fi
#        continue
    else
        if [ "${FILE_NAME##*/}" = ".DS_Store" ];then
            continue
        fi
        if [ "${FILE_NAME##*.}" = "js" ];then
            continue
        fi
        echo "$FILE_NAME 未知文件类型"
        continue;
    fi

    tar -$type -tf $FILE_NAME >/dev/null 2>&1
    if [ "$?" != "0" ];then
        echo "${FILE_NAME} 文件可能已经损坏." >&2
    fi
done;
