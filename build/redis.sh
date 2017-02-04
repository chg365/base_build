#!/bin/bash

#脚本功能：
#
#    实现Redis单机多实例情况下的正常启动、关闭、重启单个redis实例。完成系统标准服务的以下常用功能:  start|stop|status|restart
#
#    注：redis程序代码屏蔽了HUP信号，不支持在线重载配置文件，故去掉reload功能。
#
#    本脚本优化了redis停止和重启逻辑，解决原redis脚本关闭时会造成数据丢失问题。
#
# 
#
#脚本名称：
#
#    redis   #在多实例里可以按实例端口,如:redis-6001命名,以区分不同实例
#
# 
#
#脚本用法：
#
#1.在/etc/rc.d/init.d/目录下新建redis文件，将脚本内容拷贝进去
#
#2.  chkconfig --add redis   #注册服务
#
#3. chkconfig --level 345 redis on  #指定服务在3、4、5级别运行
#
#4.本人redis程序安装在/usr/local/redis目录下，配置为/usr/local/redis/bin/redis.conf，如安装在其他目录，请自行修改
#
#脚本参数:
#
#    redis -p [port]  [start|stop|status|restart]
#
#    参数说明：
#
#    -p [port] : 指定redis实例的端口，用于多实例的服务器
#
#    start：启动指定端口的Redis服务
#
#    stop：停止指定端口的Redis服务
#
#    status：进程状态
#
#    restart：先关闭Redis服务,再启动Redis服务
#
#    注：不指定端口时，脚本默认指定启动6379端口的redis
#
#用法实例：
#
#    service redis -p 6381 start  #启动6381端口实例的redis
#
#   /etc/init.d/redis  start  #默认启动6379端口实例的redis

#脚本内容：

# #!/bin/bash
#chkconfig: 2345 55 25
#description: Starts,stops and restart the redis-server
#Ver:1.1  
#Write by ND chengh(200808)
#usage: ./script_name -p [port] {start|stop|status|restart}

# Source function library.
. /etc/rc.d/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

# Check networking is up.
[ "$NETWORKING" = "no" ] && exit 0

REDIS_RETVAL=0
REDIS_PORT=6379
REDIS_PID=

if [ "$1" = "-p" ]; then
    REDIS_PORT=$2
    shift 2
fi

BASE_DIR="/usr/local/chg/base"
ETC_DIR="$BASE_DIR/etc"
REDIS_BASE_DIR="${BASE_DIR}/opt/redis"
REDIS_ETC_DIR="${ETC_DIR}/redis"
RUN_DIR="${BASE_DIR}/run"
REDIS="${REDIS_BASE_DIR}/bin/redis-server"
REDIS_PROG=$(basename $REDIS)

REDIS_CONF="${REDIS_ETC_DIR}/redis-${REDIS_PORT}.conf"
REDIS_DEFAULT_CONF="${REDIS_ETC_DIR}/redis.conf"

if [ ! -f $REDIS_CONF ]; then
    if [ -f "$REDIS_DEFAULT_CONF" ];then
        REDIS_CONF="$REDIS_DEFAULT_CONF"
    else
        echo -n $"$REDIS_CONF not exist.";warning;echo
        exit 1
    fi
fi

REDIS_PID_FILE=`grep "pidfile" ${REDIS_CONF}|cut -d ' ' -f2`
REDIS_PID_FILE=${REDIS_PID_FILE:=$RUN_DIR/redis-${REDIS_PORT}.pid}
REDIS_LOCKFILE="$RUN_DIR/redis-${REDIS_PORT}"

if [ ! -x $REDIS ]; then
    echo -n $"$REDIS not exist.";warning;echo
    exit 0
fi

start() {

    echo -n $"Starting $REDIS_PROG: "
    $REDIS $REDIS_CONF
    REDIS_RETVAL=$?
    if [ $REDIS_RETVAL -eq 0 ]; then
        success;echo;touch $REDIS_LOCKFILE
    else
        failure;echo
    fi
    return $REDIS_RETVAL

}

stop() {

    echo -n $"Stopping $REDIS_PROG: "

    if [ -f $REDIS_PID_FILE ] ;then
       read REDIS_PID <  "$REDIS_PID_FILE" 
    else 
       failure;echo;
       echo -n $"$REDIS_PID_FILE not found.";failure;echo
       return 1;
    fi

    if checkpid $REDIS_PID; then
     kill -TERM $REDIS_PID >/dev/null 2>&1
        REDIS_RETVAL=$?
        if [ $REDIS_RETVAL -eq 0 ] ;then
                success;echo 
                echo -n "Waiting for Redis to shutdown .."
         while checkpid $REDIS_PID;do
                 echo -n "."
                 sleep 1;
                done
                success;echo;rm -f $REDIS_LOCKFILE
        else 
                failure;echo
        fi
    else
        echo -n $"Redis is dead and $REDIS_PID_FILE exists.";failure;echo
        REDIS_RETVAL=7
    fi    
    return $REDIS_RETVAL

}

restart() {
    stop
    start
}

rhstatus() {
    status -p ${REDIS_PID_FILE} $REDIS_PROG
}

hid_status() {
    rhstatus >/dev/null 2>&1
}

case "$1" in
    start)
        hid_status && exit 0
        start
        ;;
    stop)
        rhstatus || exit 0
        stop
        ;;
    restart)
        restart
        ;;
    status)
        rhstatus
        REDIS_RETVAL=$?
        ;;
    *)
        echo $"Usage: $0 -p [port] {start|stop|status|restart}"
        REDIS_RETVAL=1
esac

exit $REDIS_RETVAL
