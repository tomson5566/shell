#!/bin/bash
Resettem=$(tput sgr0) 
mysql_slave_server='10.10.10.10'
mysql_user='rep'
mysql_pass='imooc'
check_mysql_server()
{
	nc -z -w2 ${mysql_slave_server} 3306 $>/dev/null
	if [ $? -eq 0 ]; then
		echo "connect ${mysql_slave_server} ok！"
		mysql -u ${mysql_user} -p${mysql_pass} -h${mysql_slave_server} -e "show slave status\G" | grep "Slave_IO_Running" | awk '{if($2!="Yes"){print "slave thread not running!"; exit 1}}' 
		if [ $? -eq 0 ]; then
			mysql -u ${mysql_user} -p${mysql_pass} -h${mysql_slave_server} -e "show slave status\G" | grep "Seconds_Behind_Master"  	

	fi


}

check_mysql_server

