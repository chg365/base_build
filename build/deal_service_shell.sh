#!/bin/bash

curr_dir=$(cd "$(dirname "$0")"; pwd);
base_define_file=`find $curr_dir -type f -name base_define.sh`;
if [ "$base_define_file" = "" ];then
    echo '查找base_define.sh文件失败';
    exit
fi

service_file="chg_base.sh"
if [ ! -f "$service_file" ]; then
    echo "服务启动文件[$service_file]不存在";
    exit;
fi

project_name=`sed -n 's/^ \{0,\}project_name=["'']\{0,1\}\([^"'']\{1,\}\)["'']\{0,1\} \{0,\};\{0,\}$/\1/p' $base_define_file`;
project_abbreviation=`sed -n 's/^ \{0,\}project_abbreviation=["'']\{0,1\}\([^"'']\{1,\}\)["'']\{0,1\} \{0,\};\{0,\}$/\1/p' $base_define_file`;
BASE_DIR=`sed -n 's/^ \{0,\}BASE_DIR=["'']\{0,1\}\([^"'']\{1,\}\)["'']\{0,1\} \{0,\};\{0,\}$/\1/p' $base_define_file`;
BASE_DIR=`eval echo -n $BASE_DIR`;

SBIN_DIR="$BASE_DIR/sbin"
#CONTRIB_BASE=`sed -n 's/^ \{0,\}CONTRIB_BASE=["'']\{0,1\}\([^"'']\{1,\}\)["'']\{0,1\} \{0,\};\{0,\}$/\1/p' $base_define_file`;
#CONTRIB_BASE=`eval echo -n $CONTRIB_BASE`;
#OPT_BASE=`sed -n 's/^ \{0,\}OPT_BASE=["'']\{0,1\}\([^"'']\{1,\}\)["'']\{0,1\} \{0,\};\{0,\}$/\1/p' $base_define_file`;
#OPT_BASE=`eval echo -n $OPT_BASE`;

cp $service_file $SBIN_DIR/$project_abbreviation;
chmod 755 $SBIN_DIR/$project_abbreviation

sed -i "s/^project_name=.\{0,\}\$/project_name=\"$(echo -n $project_name|sed 's/\//\\\//g')\"/" $SBIN_DIR/$project_abbreviation;
sed -i "s/^BASE_DIR=.\{0,\}\$/BASE_DIR=\"$( echo -n $BASE_DIR|sed 's/\//\\\//g')\"/" $SBIN_DIR/$project_abbreviation;
