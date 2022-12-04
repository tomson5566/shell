#!/bin/bash
cd /home/ndyy/service
for i in `lsof +D /home/ndyy/service/gate | awk '{print $2}' | grep -v PID`; do kill -9 $i; done && \
cd /home/ndyy/service/gate
nohup java -jar ./base.gate.jar > ./base.gate.log 2>&1 &
tail -f base.gate.log



#cd /home
#for i in `lsof +D /home/ndyy/service/async | awk '{print $2}' | grep -v PID`; do kill -9 $i; done && \
#cd /home/ndyy/service/async
#nohup java -jar ./async-service.jar > ./async-service.log 2>&1 &
#tail -f async-service.log

