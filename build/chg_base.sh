#!/bin/bash

project_name="chg_base"

service_names=`systemctl -a|grep chg_base|sed -n 's/^.\{0,\}\(chg_base\.[^ ]\{1,\}\) .\{0,\}$/\1/p'`

case "$1" in
    start)
        systemctl start "$service_names"
    ;;

    stop)
        systemctl stop "$service_names"
    ;;

    status)
        systemctl status "$service_names"
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
