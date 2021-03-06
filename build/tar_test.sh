#!/bin/bash

curr_dir=$(cd "$(dirname "$0")"; pwd);
project_name_file=${curr_dir}/project_name.sh

if [ ! -f "$project_name_file" ];then
    echo "$project_name_file is not file!" >&2
    exit 1;
fi

. $project_name_file

type="z"
for FILE_NAME in `find $PKGS_DIR -mindepth 1 -maxdepth 1 -type f `;
do
    if [ ! -s "$FILE_NAME" ];then
        echo "文件[${FILE_NAME}]为空, 删除" >&2;
        rm -f $FILE_NAME
        continue;
    fi
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
    elif [ "${FILE_NAME%%.rpm}" != "$FILE_NAME" ];then
        rpm -K --nosignature $FILE_NAME > /dev/null 2>&1
        if [ "$?" != "0" ];then
            echo "${FILE_NAME} 文件可能已经损坏." >&2
        fi
        continue
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
    elif [ "${FILE_NAME%%.ini}" != "$FILE_NAME" ];then
        continue
    elif [ "${FILE_NAME%%.xdb}" != "$FILE_NAME" ];then
        continue
    elif [ "${FILE_NAME%%.sh}" != "$FILE_NAME" ];then
        continue
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
