#! /bin/bash

DIR1=./pthreads/
DIR2=./pthreads-3.1.6/

if [[ $1 != '' ]]
then
    LOGFILE=$1
else
    LOGFILE=compare_res.txt
fi;

if [ -f $LOGFILE ]
then
  rm $LOGFILE;
fi;

for i in `find $DIR1 -type f | grep -v .svn`;
do
{
    j=${i/$DIR1/$DIR2};
    if [ -f $j ]
    then
        str1=`md5sum $i|awk '{print $1}'`;
        str2=`md5sum $j|awk '{print $1}'`;
        if [[ $str1 != $str2 ]]
        then
            # md5值不同时，diff 文件
            echo "diff $i $j 的结果为" >> $LOGFILE
            echo >> $LOGFILE
            #echo `diff $i $j >> $LOGFILE`
            echo >> $LOGFILE
        else
            echo "文件一样： $i $j" >> $LOGFILE
        fi;
    else
        echo "新增文件: $i" >> $LOGFILE
    fi
}
done;
exit;

for i in `find $DIR2 -type f |grep -v .svn`;
do
{
	
    j=${i/$DIR2/$DIR1};
    if !([ -f $j ])
    then
        echo "删除了文件: $j" >> $LOGFILE
    fi;
}
done
