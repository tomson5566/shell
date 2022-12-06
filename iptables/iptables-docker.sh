#!/bin/bash
# in docker 


# 方法一：在 docker 链中拦截, 确定不让外部访问的服务如下 (该方案最靠谱)
iptables -I DOCKER -i ens192 -p tcp --dport 9090 -j DROP
iptables -I DOCKER -i ens192 -p tcp --dport 3000 -j DROP
#iptables -I DOCKER -i ens192 -p tcp --dport 6379 -j DROP
#iptables -I DOCKER -i ens192 -p tcp --dport 8848 -j DROP
#iptables -I DOCKER -i ens192 -p tcp --dport 23306 -j DROP
#iptables -I DOCKER -i ens192 -p tcp --dport 9848 -j DROP
#iptables -I DOCKER -i ens192 -p tcp --dport 9849 -j DROP

iptables -I DOCKER -i ens192 -p tcp -s 127.0.0.1 --dport 6379 -j ACCEPT
iptables -I DOCKER -i ens192 -p tcp -s 192.168.0.52 --dport 6379 -j ACCEPT
iptables -I DOCKER -i ens192 -p tcp -s 192.168.60.0/24 --dport 6379 -j ACCEPT

iptables -I DOCKER -i ens192 -p tcp -s 127.0.0.1 --dport 8848 -j ACCEPT
iptables -I DOCKER -i ens192 -p tcp -s 192.168.0.52 --dport 8848 -j ACCEPT
iptables -I DOCKER -i ens192 -p tcp -s 192.168.60.0/24 --dport 8848 -j ACCEPT

iptables -I DOCKER -i ens192 -p tcp -s 127.0.0.1 --dport 23306 -j ACCEPT
iptables -I DOCKER -i ens192 -p tcp -s 192.168.0.52 --dport 23306 -j ACCEPT
iptables -I DOCKER -i ens192 -p tcp -s 192.168.60.0/24 --dport 23306 -j ACCEPT

iptables -I DOCKER -i ens192 -p tcp -s 127.0.0.1 --dport 8848 -j ACCEPT
iptables -I DOCKER -i ens192 -p tcp -s 192.168.0.52 --dport 8848 -j ACCEPT



iptables -I DOCKER -m iprange -i ens192 ! --src-range 192.168.1.1-192.168.1.3 -j DROP

################(以下验证方便可行。)

iptables -I DOCKER -i ens192 -p tcp -m multiport --dports 23306,9090,8848,9848,9849,3000,6379,3306,23306 -j DROP

iptables -I DOCKER -i ens192 -p tcp -s 192.168.0.0/24 -m multiport --dports 23306,9090,8848,9848,9849,3000,6379,3306,23306 -j ACCEPT
iptables -I DOCKER -i ens192 -p tcp -s 172.0.0.1/24 -m multiport --dports 23306,9090,8848,9848,9849,3000,6379,3306,23306 -j ACCEPT
iptables -I DOCKER -i ens192 -p tcp -s 192.168.60.0/24 -m multiport --dports 23306,9090,8848,9848,9849,3000,6379,3306,23306 -j ACCEPT


# 方法二：在 mangle 表的 output 中拦截
# iptables -t nat -nvL   //查看由nat 表匹配的规则


# -m multiport 支持不了 这么多端口。
# （这种方式只能组织到本地的，无法匹配外部转发的。）
iptables -t mangle -I OUTPUT -p tcp -m multiport --sports 23306,9090,8848,9848,9849,3000,6379,3306,23306 -j DROP
iptables -t mangle -I OUTPUT -p tcp -m multiport --sports 23306,9090,8848,9848,9849,3000,6379,3306,23306 -d 127.0.0.0/8 -j ACCEPT
iptables -t mangle -I OUTPUT -p tcp -m multiport --sports 23306,9090,8848,9848,9849,3000,6379,3306,23306 -d 192.168.0.0/24 -j ACCEPT
iptables -t mangle -I OUTPUT -p tcp -m multiport --sports 23306,9090,8848,9848,9849,3000,6379,3306,23306 -d 192.168.60.0/24 -j ACCEPT

iptables -t mangle -I OUTPUT -p tcp --sport 10022 -j ACCEPT
iptables -t mangle -I OUTPUT -p tcp --sport 22 -j ACCEPT
iptables -t mangle -I OUTPUT -p tcp --sport 80 -j ACCEPT
iptables -t mangle -I OUTPUT -p tcp --sport 443 -j ACCEPT


iptables -t mangle -I OUTPUT -p tcp -m multiport --sports 25,23306,6379,8111,8719,8848,8720,8721,8722,8723,8724,9848,3000,5656,9849,8189,8288,7681,9090,7778,7681 ! -d 192.168.0.0/24 -j DROP
iptables -t mangle -I OUTPUT -p tcp -m multiport --sports 25,23306,6379,8111,8719,8848,8720,8721,8722,8723,8724,9848,3000,5656,9849,8189,8288,7681,9090,7778,7681 ! -d 192.168.60.0/24 -j DROP




# 方法三： 在 mangle表的 input 链拦截； （效果不佳）
iptables -t mangle -vnL
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 25  -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 23306 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 6379 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 8111 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 8719 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 8848 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 8720 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 8721 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 8722 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 8723 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 8724 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 9848 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 3000 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 5656 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 9849 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 8189 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 8288 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 7681 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 9090 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 7778 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 127.0.0.1 --dport 7681 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 25 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 23306 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 6379 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 8111 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 8719 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 8848 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 8720 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 8721 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 8722 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 8723 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 8724 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 9848 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 3000 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 5656 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 9849 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 8189 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 8288 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 7681 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 9090 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 7778 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.0.53 --dport 7681 -j ACCEPT

iptables -t mangle -A INPUT -p tcp -s 192.168.60.0/24 --dport 6379 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.60.0/24 --dport 8848 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.60.0/24 --dport 3000 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.60.0/24 --dport 9090 -j ACCEPT
iptables -t mangle -A INPUT -p tcp -s 192.168.60.0/24 --dport 23306 -j ACCEPT


iptables -t mangle -A INPUT -p tcp --dport 25 -j DROP
iptables -t mangle -A INPUT -p tcp  --dport 23306 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 6379 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 8111 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 8719 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 8848 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 8720 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 8721 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 8722 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 8723 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 8724 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 9848 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 3000 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 5656 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 9849 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 8189 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 8288 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 7681 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 9090 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 7778 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 7681 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 7681 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 7681 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 7681 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 7681 -j DROP
iptables -t mangle -A INPUT -p tcp --dport 7681 -j DROP




