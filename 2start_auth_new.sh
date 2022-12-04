#!/bin/bash
cd /home/ndyy/service
for i in `lsof +D /home/ndyy/service/auth | awk '{print $2}' | grep -v PID`; do kill -9 $i; done && \
cd /home/ndyy/service/auth
nohup java -jar ./base.auth.server.jar > ./base.auth.server.log 2>&1 &
tail -f base.auth.server.log



#cd /home
#for i in `lsof +D /home/ndyy/service/async | awk '{print $2}' | grep -v PID`; do kill -9 $i; done && \
#cd /home/ndyy/service/async
#nohup java -jar ./async-service.jar > ./async-service.log 2>&1 &
#tail -f async-service.log

