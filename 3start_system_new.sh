#!/bin/bash
cd /home/ndyy/service
for i in `lsof +D /home/ndyy/service/system | awk '{print $2}' | grep -v PID`; do kill -9 $i; done && \
cd /home/ndyy/service/system
nohup java -jar ./supert.system.jar > ./supert.system.log 2>&1 &
tail -f supert.system.log



#cd /home
#for i in `lsof +D /home/ndyy/service/async | awk '{print $2}' | grep -v PID`; do kill -9 $i; done && \
#cd /home/ndyy/service/async
#nohup java -jar ./async-service.jar > ./async-service.log 2>&1 &
#tail -f async-service.log

