#!/bin/bash
#------------------------------------------------------
#service iptables save
#iptables-save > /opt/iptables.save
#echo 'iptables-restore /opt/iptables.save' >> /etc/rc.local
#chmod u+x /etc/rc.local
#chmod u+x /etc/rc.d/rc.local
# 清除步骤：
#iptables -P INPUT ACCEPT        #初始化必看，否则无法远程ssh
#iptables -F
#sysctl -w net.ipv4.ip_forward=1
#------------------------------------------------
iptables -t filter -A INPUT -i lo -j ACCEPT


#屏蔽 SYN_RECV 的连接
iptables -A FORWARD -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -m limit --limit 1/sec -j ACCEPT
iptables -A FORWARD -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK, RST -m limit --limit 1/sec -j ACCEPT
#限制IP碎片，每秒钟只允许100个碎片，用来防止DoS攻击
iptables -A FORWARD -f -m limit --limit 100/sec --limit-burst 100 -j ACCEPT
#限制ping包每秒一个，10个后重新开始
iptables -A FORWARD -p icmp -m limit --limit 1/sec --limit-burst 10 -j ACCEPT
#限制ICMP包回应请求每秒一个
# iptables -t filter -A INPUT -p icmp -j ACCEPT
iptables -t filter -A INPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -p icmp -m icmp --icmp-type 8 -m limit --limit 1/sec -j ACCEPT
# 解决允许Traceroute探测
iptables -A INPUT -p ICMP --icmp-type time-exceeded -j DROP
iptables -A OUTPUT -p ICMP --icmp-type time-exceeded -j DROP
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
iptables -A OUTPUT -p icmp --icmp-type echo-reply -j DROP
iptables -A INPUT -p icmp --icmp-type 8 -s 0/0 -j DROP
# ICMP timestamp 请求响应漏洞
iptables -A INPUT -p ICMP --icmp-type timestamp-request -j DROP
iptables -A INPUT -p ICMP --icmp-type timestamp-reply -j DROP

#完全接受 loopback interface 的封包
#iptables -A FORWARD -j RH-Firewall-1-INPUT
iptables -A FORWARD -p tcp -m tcp ! --tcp-flags FIN,SYN,RST,ACK, SYS -m state --state NEW -j DROP

iptables -A INPUT -i lo -j ACCEPT
#允许主机接受 ping
iptables -A INPUT -p icmp -m icmp --icmp-type any -j ACCEPT

# 网际网路印表机服务 (可以删除) 
iptables -A INPUT -p udp -m udp --dport 631 -j DROP 
iptables -A INPUT -p tcp -m tcp --dport 631 -j DROP
# 允许连线出去后对方主机回应进来的封包 
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p esp -j ACCEPT
iptables -A INPUT -p ah -j ACCEPT

# 允许防火墙开启指定端口 (本服务器规则开了常用端口 22 21 80 25 110 3306等)（netstat 运行的应用端口在这里添加。）
#iptables -A INPUT -p tcp -m state --state NEW,ESTABLISHED -m tcp --dport 21 -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW,ESTABLISHED -m tcp --dport 10022 -j ACCEPT
#iptables -A INPUT -p tcp -m state --state NEW,ESTABLISHED -m tcp --dport 25 -j ACCEPT
#iptables -A INPUT -p tcp -m state --state NEW,ESTABLISHED -m tcp --dport 110 -j ACCEPT
#iptables -A INPUT -p tcp -m state --state NEW,ESTABLISHED -m tcp --dport 111 -j ACCEPT
#iptables -A INPUT -p tcp -m state --state NEW,ESTABLISHED -m tcp --dport 123 -j ACCEPT
#iptables -A INPUT -p tcp -m state --state NEW,ESTABLISHED -m tcp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW,ESTABLISHED -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW,ESTABLISHED -m tcp --dport 443 -j ACCEPT
#iptables -A INPUT -p tcp -m state --state NEW,ESTABLISHED -m tcp --dport 3306 -j ACCEPT
#iptables -A INPUT -p tcp -m state --state NEW,ESTABLISHED -m tcp --dport 8080 -j ACCEPT
#iptables -A INPUT -p tcp -m state --state NEW,ESTABLISHED -m tcp --dport 8443 -j ACCEPT
#iptables -A INPUT -p udp -m state --state NEW,ESTABLISHED -m udp --dport 53 -j ACCEPT

iptables -A INPUT -j REJECT --reject-with icmp-host-prohibited


# 限制SSH登陆 只允许在172.16.0.2上使用ssh远程登录，从其它计算机上禁止使用ssh 
iptables -I INPUT -p tcp  -s 14.116.133.171 -j DROP
iptables -I INPUT -p tcp  -s 89.248.160.193 -j DROP
iptables -I INPUT -p tcp  -s 94.102.53.10 -j DROP
iptables -I INPUT -p tcp  -s 42.236.10.84 -j DROP
iptables -I INPUT -p tcp  -s 42.236.10.125 -j DROP
iptables -I INPUT -p tcp  -s 80.82.65.82 -j DROP
iptables -I INPUT -p tcp  -s 104.152.52.27 -j DROP
iptables -I INPUT -p tcp  -s 5.8.10.202 -j DROP
iptables -I INPUT -p tcp  -s 94.102.53.10 -j DROP
iptables -I INPUT -p tcp  -s 117.136.0.226 -j DROP
iptables -I INPUT -p tcp  -s 185.173.35.29 -j DROP
iptables -I INPUT -p tcp  -s 185.173.35.21 -j DROP
iptables -I INPUT -p tcp  -s 104.152.52.38 -j DROP
iptables -I INPUT -p tcp  -s 104.152.52.33 -j DROP
iptables -I INPUT -p tcp  -s 104.152.52.30 -j DROP
iptables -I INPUT -p tcp  -s 113.96.219.243 -j DROP
# 如果是集群 就把 集群内相互信任的ip源 全部加进来
iptables -I INPUT -p tcp  -s 192.168.0.13/24 --dport 22 -j ACCEPT
iptables -I INPUT -p tcp  -s 192.168.0.232/24 --dport 22 -j ACCEPT
iptables -I INPUT -p tcp  -s 192.168.0.11/24 --dport 22 -j ACCEPT
iptables -I INPUT -p tcp  -s 192.168.0.23/24 --dport 22 -j ACCEPT
iptables -I INPUT -p tcp  -s 192.168.0.16/24 --dport 22 -j ACCEPT
iptables -I INPUT -p tcp  -s 192.168.0.58/24 --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 16379 -m state --state NEW,ESTABLISHED -j DROP
iptables -I INPUT -p tcp  -s 192.168.0.0/24 --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j DROP
iptables -A INPUT -p tcp --dport 11521 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp --dport 10022 -m state --state NEW,ESTABLISHED -j ACCEPT

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
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 7681 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 7681 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 7681 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 127.0.0.1 --dport 7681 -m state --state NEW,ESTABLISHED -j ACCEPT
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
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 7681 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 7681 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 7681 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 7681 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -p tcp -s 192.168.0.53 --dport 7681 -m state --state NEW,ESTABLISHED -j ACCEPT



# 允许内核转发
sysctl -w net.ipv4.ip_forward=1


#nat 策略
iptables -t nat -A POSTROUTING -s 192.168.122.0/24  -o eno1 -j MASQUERADE
iptables -t nat -I POSTROUTING -p tcp -s 192.168.122.3  -j SNAT --to-source 192.168.50.197
iptables -t nat -A PREROUTING -p tcp --dport 5080 -j DNAT --to-destination 192.168.122.3:80
iptables -t nat -A PREROUTING -p tcp --dport 139 -j DNAT --to-destination 192.168.122.3:139
iptables -t nat -A PREROUTING -p tcp --dport 445 -j DNAT --to-destination 192.168.122.3:445
iptables -t nat -A PREROUTING -p udp --dport 137 -j DNAT --to-destination 192.168.122.3:137
iptables -t nat -A PREROUTING -p udp --dport 138 -j DNAT --to-destination 192.168.122.3:138
iptables -t nat -A PREROUTING -p tcp --dport 28080 -j DNAT --to-destination 192.168.122.3:8080
iptables -t nat -A PREROUTING -p tcp --dport 38080 -j DNAT --to-destination 192.168.122.3:8000
iptables -t nat -A PREROUTING -p tcp --dport 48080 -j DNAT --to-destination 192.168.122.3:48080
iptables -t nat -A PREROUTING -p tcp --dport 15050 -j DNAT --to-destination 192.168.122.3:5050
iptables -t nat -A PREROUTING -p tcp --dport 58080 -j DNAT --to-destination 192.168.122.3:58080

#iptables -P INPUT DROP    #  如果使用默认拒绝，测试清除前一定记得 连用：iptables -P INPUT ACCEPT && iptales -F
iptables -P INPUT DROP


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
iptables -t filter -A INPUT -m state --state ESTABLISHED,RELATED -j DROP
