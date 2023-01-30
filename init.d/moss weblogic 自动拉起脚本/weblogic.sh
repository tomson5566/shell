#!/bin/bash
#chkconfig:2345 99 05
#description:Weblogic Server
#/ect/init.d/weblogic
#Please edit the Variable
#export LC_ALL=zh_CN.GB18030

#. /etc/rc.d/init.d/functions
INITLOG_ARGS=""
weblogic=/app/weblogic/user_projects/domains/base_domain/bin/startWebLogic
prog=weblogic
RETVAL=0



export BEA_BASE=/app/weblogic
export BEA_HOME=$BEA_BASE/user_projects/domains/base_domain
export BEA_LOG=/app/weblogic/logs/weblogic_start.log
export PATH=$PATH:$BEA_HOME/bin
BEA_OWNER="root"
if [ ! -f$BEA_HOME/bin/startWebLogic.sh -o ! -d $BEA_HOME ]
then
    echo "WebLogic startup:cannot start"
    exit 1
fi
# depending on parameter -- startup,shutdown,restart
case "$1" in
start)
	created=`ps -ef | grep /bin/startWebLogic.sh | grep -v grep | awk '{print $2 }'`
	if [[ $created != "" ]]; then
	echo "weblogic is started"
	exit 21
	fi
	echo -n "Starting Weblogic:log file $BEA_LOG"
	touch /var/lock/weblogic
	su - $BEA_OWNER -c "nohup sh $BEA_HOME/bin/startWebLogic.sh > $BEA_LOG 2>$1 &"
    	started=`head -n 30 /app/weblogic/logs/weblogic_start.log | grep "changed to STARTING"`	
	sleep 30
	if [[ $started != "" ]]; then
	echo "------------------------ok"
	else
	echo "start error"
	fi
	;;
stop)
	echo -n "Shutdown Weblogic:"
	rm -rf /var/lock/weblogic
	su - $BEA_OWNER -c "sh $BEA_HOME/bin/stopWebLogic.sh >> $BEA_LOG"
	pid=`ps -ef | grep /app/weblogic | grep -v "grep" | awk '{print $2}'`
	if [ "$pid" != "" ]
	then
		kill -9 $pid
	else
		echo "weblogic is not running"
	fi;
	RETVAL=$?
	[ $RETVAL ==  0 ] && rm -f /var/lock/subsys/weblogic
	echo "------------------------ok"
	;;
reload|restart)
	$0 stop
	$0 start
	;;

status)
	pid=$(ps -ef | grep /app/weblogic | grep -v grep | awk '{print $2 }')
	if [ "$pid" != "" ]; then
		echo "weblogic is running"
	else
		echo "weblogic is down"
	fi
	;;
*)
	echo "Usage: `basename $0` start|restart|reload"
	exit 2
esac
exit 0
