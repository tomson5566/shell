#!/bin/bash
# 初始化
iptables -t filter -A INPUT -i lo -j ACCEPT
iptables -A FORWARD -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -m limit --limit 1/sec -j ACCEPT
iptables -A FORWARD -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK, RST -m limit --limit 1/sec -j ACCEPT
iptables -A FORWARD -f -m limit --limit 100/sec --limit-burst 100 -j ACCEPT
iptables -A FORWARD -p icmp -m limit --limit 1/sec --limit-burst 10 -j ACCEPT

iptables -A FORWARD -p icmp -m icmp --icmp-type 8 -m limit --limit 1/sec -j ACCEPT
iptables -A INPUT -p ICMP --icmp-type time-exceeded -j DROP
iptables -A OUTPUT -p ICMP --icmp-type time-exceeded -j DROP
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
iptables -A OUTPUT -p icmp --icmp-type echo-reply -j DROP
iptables -A INPUT -p icmp --icmp-type 8 -s 0/0 -j DROP
iptables -A INPUT -p ICMP --icmp-type timestamp-request -j DROP
iptables -A INPUT -p ICMP --icmp-type timestamp-reply -j DROP
iptables -A FORWARD -j RH-Firewall-1-INPUT
iptables -A FORWARD -p tcp -m tcp ! --tcp-flags FIN,SYN,RST,ACK, SYS -m state --state NEW -j DROP
iptables -A FORWARD -j RH-Firewall-1-INPUT
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

# app 端口
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 23306 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 6379 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 8111 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 8719 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 8848 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 8720 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 8721 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 8722 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 8723 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 8724 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 9848 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 3000 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 5656 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 9849 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 8189 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 8288 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 7681 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 9090 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 7778 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 7681 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 23306 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 6379 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 8111 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 8719 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 8848 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 8720 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 8721 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 8722 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 8723 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 8724 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 9848 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 3000 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 5656 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 9849 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 8189 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 8288 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 7681 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 9090 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 7778 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 7681 -m state --state NEW,ESTABLISHED -j ACCEPT



iptables -t filter -A INPUT -p tcp --dport 25 -j DROP
iptables -t filter -A INPUT -p tcp  --dport 23306 -j DROP
iptables -t filter -A INPUT -p tcp --dport 6379 -j DROP
iptables -t filter -A INPUT -p tcp --dport 8111 -j DROP
iptables -t filter -A INPUT -p tcp --dport 8719 -j DROP
iptables -t filter -A INPUT -p tcp --dport 8848 -j DROP
iptables -t filter -A INPUT -p tcp --dport 8720 -j DROP
iptables -t filter -A INPUT -p tcp --dport 8721 -j DROP
iptables -t filter -A INPUT -p tcp --dport 8722 -j DROP
iptables -t filter -A INPUT -p tcp --dport 8723 -j DROP
iptables -t filter -A INPUT -p tcp --dport 8724 -j DROP
iptables -t filter -A INPUT -p tcp --dport 9848 -j DROP
iptables -t filter -A INPUT -p tcp --dport 3000 -j DROP
iptables -t filter -A INPUT -p tcp --dport 5656 -j DROP
iptables -t filter -A INPUT -p tcp --dport 9849 -j DROP
iptables -t filter -A INPUT -p tcp --dport 8189 -j DROP
iptables -t filter -A INPUT -p tcp --dport 8288 -j DROP
iptables -t filter -A INPUT -p tcp --dport 7681 -j DROP
iptables -t filter -A INPUT -p tcp --dport 9090 -j DROP
iptables -t filter -A INPUT -p tcp --dport 7778 -j DROP
iptables -t filter -A INPUT -p tcp --dport 7681 -j DROP
iptables -t filter -A INPUT -p tcp --dport 7681 -j DROP
iptables -t filter -A INPUT -p tcp --dport 7681 -j DROP
iptables -t filter -A INPUT -p tcp --dport 7681 -j DROP
iptables -t filter -A INPUT -p tcp --dport 7681 -j DROP
iptables -t filter -A INPUT -p tcp --dport 7681 -j DROP
iptables -t filter -A INPUT -m state --state NEW,ESTABLISHED,RELATED -j DROP













