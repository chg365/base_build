#!/bin/bash

# project_name不要有特殊字符
project_name="chg_base"

# 这样查出来，进程间启动、停止的先后顺序呢？
service_names=`systemctl -a|grep $project_name|sed -n "s/^.\{0,\}\(${project_name}\.[^ ]\{1,\}\) .\{0,\}$/\1/p"`

if [ "$service_names" = "" ]; then
    echo "没有找到项目下的服务!" >&2
    exit 1;
fi

case "$1" in
    start)
        systemctl start `echo "$service_names"`
    ;;

    stop)
        systemctl stop `echo "$service_names"`
    ;;

    status)
        systemctl status `echo "$service_names"`
    ;;

    restart)
        $0 stop
        $0 start
    ;;

    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
    ;;

esac
