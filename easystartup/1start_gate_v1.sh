#!/bin/bash
###########v1################
#cd /home/ndyy/service
#for i in `lsof +D /home/ndyy/service/gate | awk '{print $2}' | grep -v PID`; do kill -9 $i; done && \
#cd /home/ndyy/service/gate
#nohup java -jar ./base.gate.jar > ./base.gate.log 2>&1 &
#tail -f base.gate.log
###########v1###############

appname=$(cd /home/supert/app/ && ls base.auth*.jar)

pids=$(jps | grep base.auth | awk '{print $1}')
if [[ -z $pids ]]
then
	exit 1
	echo "app is not running!"
else
	kill -9 $pids
fi

nohup java -Xms256m -Xmx1024m -XX:PermSize=32m -XX:MaxPermSize=512m -DCONFIG_SERVER_ADDR=localhost:8848 -jar $appname -spring.profiles.active=pro >$app.log 2>&1&








#cd /home
#for i in `lsof +D /home/ndyy/service/async | awk '{print $2}' | grep -v PID`; do kill -9 $i; done && \
#cd /home/ndyy/service/async
#nohup java -jar ./async-service.jar > ./async-service.log 2>&1 &
#tail -f async-service.log

