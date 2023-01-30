### BEGIN WLS Configration







DOMAIN_NAME=lineloss_domain







SERVER_NAME=lineloss_Server







ADMIN_URL="t3://192.168.0.85:7009"







DOMAIN_PATH=/home/oracle/Oracle/Middleware/user_projects/domains/${DOMAIN_NAME}







#使用这个命令得到weblogic对应服务进程的进程号







WLS_PID=`ps -ef|grep java|grep =${SERVER_NAME}|awk '{print $2}'`







#USER_NAME=`logname`







USER_NAME=`whoami`







## WLS_MEMORY







USER_MEM_ARGS="-Xms2048m -Xmx3096m -XX:PermSize=256m -XX:MaxPermSize=512m"







export USER_MEM_ARGS







### END WLS Configration







 







######### Weblogic server start|stop|restart|status







#用于等待进程启停







wait_for_pid ()







{







  try=0







    case "$1" in







      'created')







        while test $try -lt 7 ; do







        printf .







        try=`expr $try + 1`







        sleep 1







        done           







        WLS_PID=`ps -ef|grep java|grep ${SERVER_NAME}|awk '{print $2}'`           







        if [ "$WLS_PID" != "" ] ; then







          try=''                        







        fi







      ;;







      'removed')







        while test $try -lt 35 ; do 







        WLS_PID=`ps -ef|grep java|grep ${SERVER_NAME}|awk '{print $2}'`







        if [ "${WLS_PID}" = "" ] ; then







          try=''







        break







        fi







        printf .







        try=`expr $try + 1`







        sleep 1







        done







      ;;







    esac







}











#domain不能为空







if [ "$DOMAIN_NAME" = "" ] ; then







  echo "DOMAIN_NAME is not set! Plz set DOMAIN_NAME!"







  exit 1







fi







#service不能为空







if [ "$SERVER_NAME" = "" ] ; then







  echo "SERVER_NAME is not set! Plz set SERVER_NAME!"







  exit 1







fi







#url不能为空







if [ "$ADMIN_URL" = "" ] ; then







  echo "ADMIN_URL is not set! Using default ADMIN_URL!"







fi







#如果是查看状态命令      







if [ "$1" = "status" ]







  then       







  if [ "${WLS_PID}" = "" ] ; then







   echo "No pid - $SERVER_NAME is not running !"







    exit 1







 else







  echo "$SERVER_NAME is running !"







  exit 0







 fi







fi







printf "Terminating $SERVER_NAME "







  if [ "${WLS_PID}" = "" ] ; then







    echo "No pid - $SERVER_NAME is not running !"







  else         







    kill -9 $WLS_PID







  wait_for_pid removed







  if [ -n "$try" ] ; then







  echo " failed "







  exit 1        







  fi







    echo " done ! "







    exit 0







 fi







#如果是停止命令，这里不使用这个       







if [ "$1" = "stop" ]







then       







echo ""







else







#启动命令







printf "Starting $SERVER_NAME "







  if echo $SERVER_NAME|grep -q dmin ; then       







    nohup sh $DOMAIN_PATH/bin/startWebLogic.sh &







  else       







    nohup sh $DOMAIN_PATH/bin/startManagedWebLogic.sh $SERVER_NAME $ADMIN_URL &







  fi       







  wait_for_pid created







  if [ -n "$try" ] ; then







    echo " failed "







    exit 1







  else







    echo " done ! "







    exit 0







  fi  







fi







echo "To check the log, you may excute:"







echo "tail -100f "