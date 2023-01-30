#!/bin/bash
clear
if [[ $# -eq 0 ]]
then
# Define Variable reset_terminal
reset_terminal=$(tput sgr0) 

# check os type
os=$(uname -o)
# check os release version and name
os=$(cat /etc/issue | grep -e "S")
# check architecture
architcture=$(unmae -m)
kernerrelease=$(uname -r)
# check hostname
hostname=$(uname -n)
# check internal ip
internalip=$(hostname -I)
# check external ip
externalip=$(curl -s http://ipecho.net/plain)

# check dns
nameservers=$(cat /etc/resolv.conf | grep -E "\<nameserver[ ]+" | awk '{print $NF}')
# check if connected to internet or not 
ping -c 2 jd.com &>/dev/null && echo 'internet:connected' || echo 'internet:disconnected'
# check logged in users
who
# mem
system_mem_usages=$(awk '/MemTotal/{total=$2}/MemFree/{free=$2}END{print (total-free)/1024 "M"}' /proc/meminfo)
app_mem_usages=${awk '/MemTotal/{total=$2}/MemFree/{free=$2}/^Cached/{cached=$2}/Buffers/{buffer=$2}END{print (total-free-cached-buffer)/1024 "M"}' /proc/meminfo}
loadaverge=$(top -n 1 -b | grep 'load average' | awk '{print $12 $13 $14}')
diskaverage=$(df -hP | grep -vE 'Filesystem|tmp|overlay|shm' | awk '{print $1 "\t " $5}')



fi