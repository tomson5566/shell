#!/bin/bash
is_setupdocker=`docker &> /dev/null && echo $? || echo $?`; if [[ $is_setupdocker -ne 0 ]]; then echo 'docker is not install sorry!!'; exit 3; else echo 'docker is install ok'; fi
is_setupcompose=`docker-compose &> /dev/null && echo $? || echo $?`; if [[ $is_setupcompose -ne 0 ]]; then echo 'docker-compose is not install sorry!!'; exit 3; else echo 'docker-compose is install ok'; fi
nettools=`netstat &> /dev/null && echo $? || echo $?`; if [[ $nettools -ne 0 ]]; then echo 'netstat is not install sorry!!'; exit 3; else echo 'netstat is install ok'; fi
javatools=`jps &> /dev/null && echo $? || echo $?`; if [[ $javatools -ne 0 ]]; then echo 'java is not install sorry!!'; exit 3; else echo 'java is install ok'; fi



export JAVA_HOME=/home/isc/jdk1.8.0_101
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib:$CLASSPATH
export JAVA_PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin
export PATH=$PATH:${JAVA_PATH}
# 定义需要放行的ip地址，或网段，如果是ip地址就不用写掩码；
allowip=(192.168.0.0/24 192.168.60.0/24 192.168.30.0/24)
# 定义运行远程登陆sshd 的主机ip
allowsship=(192.168.1.0/24 192.168.1.1 192.168.60.53)

# 设置/etc/hosts.allow 功能
for a in `echo ${!allowsship[@]}`;
do
ifinhostdeny=`grep ${allowsship[$a]} /etc/hosts.allow >> /dev/null && echo $? || echo $?`
	if [[ $ifinhostdeny -ne 0 ]]; then
	echo "sshd: ${allowsship[$a]}" >> /etc/hosts.allow
	fi
done

# 初始化中间件功能
init_start() {
dockerstatus=$(docker ps &>> /dev/null  && echo $? || echo $?)
systemctl enable docker
systemctl enable nginx
if [[ $dockerstatus -ne 0 ]]; then
systemctl start docker
sleep 10
fi
nacosstatus=$(docker ps | grep nacos &>>/dev/null && echo $? || echo $?)

nacosmysqlstatus=$(docker ps | grep mysql:8.0.30 &>>/dev/null && echo $? || echo $?)

if [[ $nacosmysqlstatus -ne 0 ]]; then
	cd /root/docker-compose/example && docker-compose down && sleep 1
	cd /root/docker-compose/example && docker-compose up -d
else
	if [[ $nacosstatus -ne 0 ]]; then
		cd /root/docker-compose/example && docker-compose down && sleep 1
		cd /root/docker-compose/example && docker-compose up -d
	fi
fi
#cd /root/docker-compose/example && docker-compose down
sleep 2
#cd /root/docker-compose/example && docker-compose up -d
cd /root/docker-compose/mysql8 && docker-compose up -d
cd /root/docker-compose/redis && docker-compose up -d
}

# 启动 app 下的 jar 包功能
all_start() {
appPath='/home/supert/app'
newAppPath='/home/supert/newapp'
appBakPath='/home/supert/appbak'
source /etc/profile

if [ -d ${appPath} ]; then
  echo "存在目录${appPath}"
else
  echo "不存在目录${appPath}"	
fi

if [ -d ${newAppPath} ]; then
  echo "存在目录${newAppPath}"
else
  echo "不存在目录${newAppPath}"
fi


echo "第一步，杀死进程..."

apps=`find ${appPath} -name '*.jar'`

#杀死旧进程
for dir in $apps
do
  pid=`ps -ef | grep $dir | grep -v grep | awk '{print $2}'`
  if [ -n "$pid" ]
  then
    echo "kill pid ${pid}"	
    kill -9 $pid
  fi
done



# 判断是否有新的更新
echo "第二步，判断是否有新的更新..."

newapp=`find ${newAppPath} -name '*.jar'`

arr=(${newapp// / })


current=`date "+%Y-%m-%d %H:%M:%S"`  
timeStamp=`date -d "$current" +%s`   
#将current转换为时间戳，精确到毫秒  
currentTimeStamp=$((timeStamp*1000+`date "+%N"`/1000000)) 
echo $currentTimeStamp


if [ ${#arr[*]} -gt 0 ];then	
    echo "新的更新：${#arr[*]}"
    mv ${appPath} /home/supert/appbak/app${currentTimeStamp} && mv ${newAppPath} ${appPath}
fi


# 判断是否有新的更新
echo "第三步，启动..."

apps=`find ${appPath} -name '*.jar'`

for app in $apps
do
    echo ${app} 
    #nohup java -Xms256m -Xmx1024m -XX:PermSize=32m -XX:MaxPermSize=512m -jar $app --spring.profiles.active=pro >$app.log 2>&1&
    nohup java -Xms256m -Xmx1024m -XX:PermSize=32m -XX:MaxPermSize=512m -DCONFIG_SERVER_ADDR=127.0.0.1:8848 -jar $app --spring.profiles.active=pro >$app.log 2>&1&

done 


echo "完成."
}

# 启动单个 jar包功能；
auth_start() {
#appname=$(cd /home/supert/app/ && ls base.auth*.jar)
appname=$(find /home/supert/app -name '*.jar' | grep base.auth)
pids=$(jps | grep base.auth | awk '{print $1}')
if [[ -z $pids ]]
then
	echo "app is not running! start now"
else
	kill -9 $pids
fi
echo "$appname restart now"
cd /home/supert/app/
echo "$appname restart now"
nohup java -Xms256m -Xmx1024m -XX:PermSize=32m -XX:MaxPermSize=512m -DCONFIG_SERVER_ADDR=localhost:8848 -jar $appname -spring.profiles.active=pro >$app.log 2>&1&
}

gate_start() {
#appname=$(cd /home/supert/app/ && ls base.gate*.jar)
appname=$(find /home/supert/app -name '*.jar' | grep base.gate)
pids=$(jps | grep base.gate | awk '{print $1}')
if [[ -z $pids ]]
then
        echo "app is not running! start now"
else
        kill -9 $pids
fi
sleep 6
cd /home/supert/app/
echo "$appname restart now"
nohup java -Xms256m -Xmx1024m -XX:PermSize=32m -XX:MaxPermSize=512m -DCONFIG_SERVER_ADDR=localhost:8848 -jar $appname -spring.profiles.active=pro >$app.log 2>&1&
}

system_start() {
#appname=$(cd /home/supert/app/ && ls supert.system*.jar)
appname=$(find /home/supert/app -name '*.jar' | grep supert.system)
pids=$(jps | grep supert.system | awk '{print $1}')
if [[ -z $pids ]]
then
        echo "app is not running! start now"
else
        kill -9 $pids
fi
cd /home/supert/app/
echo "$appname restart now"
nohup java -Xms256m -Xmx1024m -XX:PermSize=32m -XX:MaxPermSize=512m -DCONFIG_SERVER_ADDR=localhost:8848 -jar $appname -spring.profiles.active=pro >$app.log 2>&1&
}

admin_start() {
#appname=$(cd /home/supert/app/ && ls admin-service*.jar)
appname=$(find /home/supert/app -name '*.jar' | grep admin-service)
pids=$(jps | grep admin-service | awk '{print $1}')
if [[ -z $pids ]]
then
        echo "app is not running! start now"
else
        kill -9 $pids
fi
cd /home/supert/app/
echo "$appname restart now"
nohup java -Xms256m -Xmx1024m -XX:PermSize=32m -XX:MaxPermSize=512m -DCONFIG_SERVER_ADDR=localhost:8848 -jar $appname -spring.profiles.active=pro >$app.log 2>&1&
}

rsync_start() {
#appname=$(cd /home/supert/app/ && ls async-service*.jar)
appname=$(find /home/supert/app -name '*.jar' | grep async-service)
pids=$(jps | grep async-service | awk '{print $1}')
if [[ -z $pids ]] 
then
        echo "app is not running! start now"
else
        kill -9 $pids
fi
cd /home/supert/app/
echo "$appname restart now"
nohup java -Xms256m -Xmx1024m -XX:PermSize=32m -XX:MaxPermSize=512m -DCONFIG_SERVER_ADDR=localhost:8848 -jar $appname -spring.profiles.active=pro >$app.log 2>&1&
}

screen_start() {
#appname=$(cd /home/supert/app/ && ls screen-service*.jar)
appname=$(find /home/supert/app -name '*.jar' | grep screen-service)
pids=$(jps | grep screen-service | awk '{print $1}')
if [[ -z $pids ]]
then
        echo "app is not running! start now"
else
        kill -9 $pids
fi
cd /home/supert/app/
echo "$appname restart now"
nohup java -Xms256m -Xmx1024m -XX:PermSize=32m -XX:MaxPermSize=512m -DCONFIG_SERVER_ADDR=localhost:8848 -jar $appname -spring.profiles.active=pro >$app.log 2>&1&
}

# 动态设置防火墙功能
iptables_set() {
localip=($(hostname -I))


ip a | grep ^[0-9] | awk '{print $2}' | awk -F: '{print $1}' > ifdev.txt
netstat -anptu | grep LISTEN | awk '{print $4}' | awk -F ':' '{print $NF}' > listen.txt
ifdev=(`cat ifdev.txt`)


iplisten=(`cat listen.txt`)
netstat -anptu | grep LISTEN | grep docker | awk '{print $4}' | awk -F ':' '{print $NF}' > dockerport.txt
DockerPort=(`cat dockerport.txt`)
iptables -t filter -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p ICMP --icmp-type time-exceeded -j DROP
iptables -A OUTPUT -p ICMP --icmp-type time-exceeded -j DROP
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
iptables -A OUTPUT -p icmp --icmp-type echo-reply -j DROP
iptables -A INPUT -p icmp --icmp-type 8 -s 0/0 -j DROP
iptables -A INPUT -p ICMP --icmp-type timestamp-request -j DROP
iptables -A INPUT -p ICMP --icmp-type timestamp-reply -j DROP
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
	for s in `echo ${!localip[@]}`;
	do
	iptables -t filter -A INPUT -p tcp -s ${localip[$s]} --dport ${iplisten[$j]} -m state --state NEW,ESTABLISHED -j ACCEPT
	done
iptables -t filter -A INPUT -p tcp --dport ${iplisten[$j]} -j DROP
done

for i in `echo ${!ifdev[@]}`;
do
iptables -t filter -I INPUT -i ${ifdev[$i]} -j ACCEPT
done

for d in `echo ${!DockerPort[@]}`;
do
iptables -I DOCKER -i ens192 -p tcp --dport ${DockerPort[$d]} -j DROP
# 放行访问docker 端口的网段
	for l in `echo ${!allowip[@]}`;
	do
	iptables -I DOCKER -i ens192 -p tcp -s ${allowip[$l]} --dport ${DockerPort[$d]} -j ACCEPT
	done
done
iptables -I DOCKER -i ens192 -p tcp -s 172.0.0.0/24 -j ACCEPT

sleep 1
rm -rf ifdev.txt listen.txt dockerport.txt
}


iptable_init() {
ifsave=$(iptables -nvL | grep 631 >> /dev/null && echo $? || echo $?)
if [[ $ifsave -ne 0 ]]; then
	echo "iptables is not set, reset now"
	iptables_set
else
	echo "iptables is seted, Nothing to do"
fi
}


case "$1" in
all_start)
	init_start && \
	all_start
;;
init_start)
	init_start
;;
auth_start)
	auth_start
;;
gate_start)
	gate_start
;;
system_start)
	system_start
;;

admin_start)
	admin_start
;;

rsync_start)
	rsync_start
;;

screen_start)
	screen_start
;;
iptable_init)
	iptable_init
;;
*)
	echo $"Usage: $0 {all_start|init_start|gate_start|auth_start|system_start|admin_start|rsync_start|screen_start|iptable_init}"
    	exit 2

esac	

