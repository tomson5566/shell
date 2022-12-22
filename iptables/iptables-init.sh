#!/bin/bash
ip a | grep ^[0-9] | awk '{print $2}' | awk -F: '{print $1}' > ifdev.txt
netstat -anptu | grep LISTEN | awk '{print $4}' | awk -F ':' '{print $NF}' > listen.txt
ifdev=(`cat ifdev.txt`)
localip=192.168.0.52

iplisten=(`cat listen.txt`)

netstat -anptu | grep LISTEN | grep docker | awk '{print $4}' | awk -F ':' '{print $NF}' > dockerport.txt
DockerPort=(`cat dockerport.txt`)


iptables -t filter -A INPUT -i lo -j ACCEPT
#iptables -A FORWARD -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -m limit --limit 1/sec -j ACCEPT
#iptables -A FORWARD -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK, RST -m limit --limit 1/sec -j ACCEPT
#iptables -A FORWARD -f -m limit --limit 1000/sec --limit-burst 100 -j ACCEPT
#iptables -A FORWARD -p icmp -m limit --limit 1/sec --limit-burst 10 -j ACCEPT

#iptables -A FORWARD -p icmp -m icmp --icmp-type 8 -m limit --limit 1/sec -j ACCEPT
iptables -A INPUT -p ICMP --icmp-type time-exceeded -j DROP
iptables -A OUTPUT -p ICMP --icmp-type time-exceeded -j DROP
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
iptables -A OUTPUT -p icmp --icmp-type echo-reply -j DROP
iptables -A INPUT -p icmp --icmp-type 8 -s 0/0 -j DROP
iptables -A INPUT -p ICMP --icmp-type timestamp-request -j DROP
iptables -A INPUT -p ICMP --icmp-type timestamp-reply -j DROP
#iptables -A FORWARD -p tcp -m tcp ! --tcp-flags FIN,SYN,RST,ACK -m state --state NEW -j DROP
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -m icmp --icmp-type any -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 631 -j DROP 
iptables -A INPUT -p tcp -m tcp --dport 631 -j DROP
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p esp -j ACCEPT
iptables -A INPUT -p ah -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 10022 -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW,ESTABLISHED -m tcp --dport 10022 -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW,ESTABLISHED -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW,ESTABLISHED -m tcp --dport 443 -j ACCEPT
iptables -A INPUT -j REJECT --reject-with icmp-host-prohibited
iptables -t filter -I INPUT -p tcp -s 127.0.0.1 -j ACCEPT


for j in `echo ${!iplisten[@]}`;
do
iptables -t filter -A INPUT -p tcp -s $localip --dport ${iplisten[$j]} -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp --dport ${iplisten[$j]} -j DROP
done



# 允许本地接收 来自docker网络的回包
for i in `echo ${!ifdev[@]}`;
do
iptables -t filter -I INPUT -i ${ifdev[$i]} -j ACCEPT
#iptables -t filter -I INPUT -i br-e6af8b661e43 -j ACCEPT
#iptables -t filter -I INPUT -i br-6ace888e68be -j ACCEPT
#iptables -t filter -I INPUT -i br-f0f8e042bbae -j ACCEPT
#iptables -t filter -I INPUT -i br-3ab77afedf4b -j ACCEPT
#iptables -t filter -I INPUT -i lo -j ACCEPT
done



 

#iptables -t filter -A INPUT -m state --state NEW,ESTABLISHED,RELATED -j DROP
#iptables -t filter -A INPUT -m state --state NEW,ESTABLISHED,RELATED -j DROP

# docker port
for d in `echo ${!DockerPort[@]}`;
do
iptables -I DOCKER -i ens192 -p tcp --dport ${DockerPort[$d]} -j DROP
#iptables -I DOCKER -i ens192 -p tcp -m multiport --dports 23306,9090,8848,9848,9849,3000,6379,3306,23306 -j DROP
# 放行访问docker 端口的网段
iptables -I DOCKER -i ens192 -p tcp -s 192.168.0.0/24 --dport ${DockerPort[$d]} -j ACCEPT
iptables -I DOCKER -i ens192 -p tcp -s 192.168.60.0/24 --dport ${DockerPort[$d]} -j ACCEPT
iptables -I DOCKER -i ens192 -p tcp -s 192.168.3.0/24 --dport ${DockerPort[$d]} -j ACCEPT

#iptables -I DOCKER -i ens192 -p tcp -s 192.168.0.0/24 -m multiport --dports 23306,9090,8848,9848,9849,3000,6379,3306,23306 -j ACCEPT
#iptables -I DOCKER -i ens192 -p tcp -s 172.0.0.0/24 -j ACCEPT
#iptables -I DOCKER -i ens192 -p tcp -s 192.168.60.0/24 -m multiport --dports 23306,9090,8848,9848,9849,3000,6379,3306,23306 -j ACCEPT
#iptables -I DOCKER -i ens192 -p tcp -s 10.7.7.137 -m multiport --dports 23306,9090,8848,9848,9849,3000,6379,3306,23306 -j ACCEPT
#iptables -I DOCKER -i ens192 -p tcp -s 192.168.3.0/24 -m multiport --dports 23306,9090,8848,9848,9849,3000,6379,3306,23306 -j ACCEPT

#iptables -I DOCKER -i ens192 -p tcp -s 10.7.7.0/24 -m multiport --dports 23306,9090,8848,9848,9849,3000,6379,3306,23306 -j DROP
done

iptables -I DOCKER -i ens192 -p tcp -s 172.0.0.0/24 -j ACCEPT



sleep 1
rm -rf ifdev.txt listen.txt dockerport.txt
