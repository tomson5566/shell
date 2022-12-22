#!/bin/bash

#cd /root/docker-compose/example && docker-compose up -d
#cd /root/docker-compose/mysql8 && docker-compose up -d
#cd /root/docker-compose/redis && docker-compose up -d


appPath='/home/supert/app'
newAppPath='/home/supert/newapp'
appBakPath='/home/supert/appbak'


if [ -d ${appPath} ]; then
  echo "存在目录${appPath}"
else
  echo "不存在目录${appPath}"	
fi

if [ -d ${newAppPath} ]; then
  echo "存在目录${newAppPath}"
else
  echo "不存在目录${newAppPath}"
fi


echo "第一步，杀死进程..."

apps=`find ${appPath} -name '*.jar'`

#杀死旧进程
for dir in $apps
do
  pid=`ps -ef | grep $dir | grep -v grep | awk '{print $2}'`
  if [ -n "$pid" ]
  then
    echo "kill pid ${pid}"	
    kill -9 $pid
  fi
done



# 判断是否有新的更新
echo "第二步，判断是否有新的更新..."

newapp=`find ${newAppPath} -name '*.jar'`

arr=(${newapp// / })


current=`date "+%Y-%m-%d %H:%M:%S"`  
timeStamp=`date -d "$current" +%s`   
#将current转换为时间戳，精确到毫秒  
currentTimeStamp=$((timeStamp*1000+`date "+%N"`/1000000)) 
echo $currentTimeStamp


if [ ${#arr[*]} -gt 0 ];then	
    echo "新的更新：${#arr[*]}"
    mv ${appPath} /home/supert/appbak/app${currentTimeStamp} && mv ${newAppPath} ${appPath}
fi


# 判断是否有新的更新
echo "第三步，启动..."

apps=`find ${appPath} -name '*.jar'`

for app in $apps
do
    echo ${app} 
    #nohup java -Xms256m -Xmx1024m -XX:PermSize=32m -XX:MaxPermSize=512m -jar $app --spring.profiles.active=pro >$app.log 2>&1&
    nohup java -Xms256m -Xmx1024m -XX:PermSize=32m -XX:MaxPermSize=512m -DCONFIG_SERVER_ADDR=127.0.0.1:8848 -jar $app --spring.profiles.active=pro >$app.log 2>&1&

done 


echo "完成."
