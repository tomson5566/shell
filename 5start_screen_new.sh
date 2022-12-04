#!/bin/bash
cd /home/ndyy/service
for i in `lsof +D /home/ndyy/service/screen | awk '{print $2}' | grep -v PID`; do kill -9 $i; done && \
cd /home/ndyy/service/screen
#nohup java -jar ./admin-service.jar > ./admin-service.log 2>&1 &
nohup java -jar ./screen-service.jar > ./screen-service.log 2>&1 &
tail -f screen-service.log
#tail -f admin-service.log



#cd /home
#for i in `lsof +D /home/ndyy/service/async | awk '{print $2}' | grep -v PID`; do kill -9 $i; done && \
#cd /home/ndyy/service/async
#nohup java -jar ./async-service.jar > ./async-service.log 2>&1 &
#tail -f async-service.log

