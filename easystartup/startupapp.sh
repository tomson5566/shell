#!/bin/bash
cd /home/ndyy/service && ./1start_gate.sh
sleep 5
cd /home/ndyy/service && ./2start_auth_new.sh
sleep 6
cd /home/ndyy/service && ./3start_system_new.sh
sleep 5
cd /home/ndyy/service && ./4start_admin_new.sh
sleep 6
cd /home/ndyy/service && ./5start_screen_new.sh
sleep 5
cd /home/ndyy/service && ./6start_async_new.sh
