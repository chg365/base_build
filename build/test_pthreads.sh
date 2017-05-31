#!/bin/bash
function test1() {
    for ((i=0; i<=$#; i++));do
        echo ${!i};
    done
}

function my_cmd() {
    param=$1
    t=$RANDOM
    t=$[t%15]
    sleep $t
    echo "pid[$$] [$param] sleep $t s"
}
function pthreads () {
    local task_name=$1
    local func_name=$2
    local thread_num=$3 # 最大可同时执行线程数量
    local params_name=$4

    job_num=100   # 任务总数
    if [ -z "task_name" ];then
        echo "请指定任务名"
        return 1;
    fi

    #type -t 打印alias,keyword,function,built-in,file这5种类型
    local tmp=`type -t "${func_name}"`
    if [ "$?" != "0" -o "$tmp" = "keyword" ];
    then
        echo "函数或命令[$func_name]未实现"
        return 1;
    fi


        for i in ${params_name[*]};do
            echo $i
        done;
    echo "bbbbbbbbbbbbbbbbbbb"
        echo $5
        exit;
    if ! test "$thread_num" -gt "0" 2>/dev/null;then
        echo "程序组并发数参数错误. num: $thread_num"
        return 1;
    fi


    tmp_fifofile="/tmp/${task_name}_$$.fifo";
    mkfifo $tmp_fifofile ;      # 新建一个fifo类型的文件
    exec 6<>$tmp_fifofile ;     # 将fd6指向fifo类型
    rm $tmp_fifofile ;   #删也可以


    #根据线程总数量设置令牌个数
    for ((i=0;i<${thread_num};i++));do
        echo
    done >&6

    for ((i=0;i<${job_num};i++));do # 任务数量
        # 一个read -u6命令执行一次，就从fd6中减去一个回车符，然后向下执行，
        # fd6中没有回车符的时候，就停在这了，从而实现了线程数量控制
        read -u6

        #可以把具体的需要执行的命令封装成一个函数
        {
            $func_name $i
            echo >&6 # 当进程结束以后，再向fd6中加上一个回车符，即补上了read -u6减去的那个
        } &

    done

    wait
    exec 6>&- # 关闭fd6
}

# {{{ function function_exists() 检测函数是否定义
function function_exists()
{
    type -t "$0" 2>/dev/null|grep -q 'function'
    if [ "$?" != "0" ];then
        return 1;
    fi
    return 0;
}
# }}}

arr=( "aaaa" "bbb" "cc dd" )
test1 "${arr[@]}"
exit;
test1 1 2 3 4 5 6 7 8 9 10 13 156 134 dd "cc bb"
exit;
arr=( "aaaa" "bbb" "cc dd" )

pthreads test "my_cmd" 6 "${arr[@]}"
