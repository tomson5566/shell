#!/bin/bash
wpid=$(ps -ef | grep /app/weblogic | grep -v grep | awk '{print $2 }' | wc -l)
if [ "$wpid" -eq 0 ]; then
        echo $wpid
       /etc/init.d/weblogic start &
fi
