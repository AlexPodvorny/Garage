#!/bin/bash

LOG_FILE=/var/log/cycle
# Function to write to the Log file
###################################

write_log() 
{
  while read text
  do 
  	#LOGTIME=`date "+%Y-%m-%d %H:%M:%S"`
  	LOGTIME=`date "+%H:%M:%S"`
  	# If log file is not defined, just echo the output
  	if [ "$LOG_FILE" == "" ]; then 
	echo $LOGTIME": $text";
  	else
    	LOG=$LOG_FILE"_"`date +%Y%m%d`
	touch $LOG
    	if [ ! -f $LOG ]; then echo "ERROR!! Cannot create log file $LOG. Exiting."; exit 1; fi
	echo $LOGTIME": $text" | tee -a $LOG;
  	fi
  done
}

# settings
. /etc/master/settings.sh

# delay start for init modules
sleep 30
echo "System started" | write_log
#---------------------------------------------------------------------------
# START

if [ ! -d "$DATA_PATH" ]; then
  mkdir $DATA_PATH
  chmod 0666 $DATA_PATH
fi

while : 
do
#---------------------------------------------------------------------------
rm -f $DATA_PATH/*

# проверка GPIO
if [ -f  /sys/class/gpio/gpio0/value ]
then
	echo 0 > /sys/class/gpio/gpio0/value
fi
if [ -f  sys/class/gpio/gpio4/value ]
then
	echo 1 > /sys/class/gpio/gpio4/value
fi


#---------------------------------------------------------------------------

## TODO - ???
## Downloading the latest menu from the web
#echo "Downloading the latest menu from the web" | write_log
#echo Getting menu from $UPDATES_URL/menu2.php?download=1\&id=$MASTER_ID
#wget -O $DATA_PATH/menu.tmp  $UPDATES_URL/menu2.php?download=1\&id=$MASTER_ID
#if grep -Fq "stylesheet" $DATA_PATH/menu.tmp
#then
#mv $DATA_PATH/menu.tmp $WEB_PATH/menu.html
#else
#echo Incorrect menu file
#fi
#---------------------------------------------------------------------------

START_TIME="$(date +%s)"
# main cycle
#---------------------------------------------------------------------------
while [ 1=1 ] ; do

LINE="CYCLE"

echo "Cycle start" | write_log
PASSED_TIME="$(($(date +%s)-START_TIME))"

PACKET_ID=""
DATA_FROM=""
DATA_TO=""
DATA_COMMAND=""
DATA_VALUE=""

REGEX='^P:([0-9]+);F:([0-9]+);T:([0-9]+);C:([0-9]+);D:([0-9]+);$'

# чтение датчиков
. /etc/master/sensors.sh
echo "Sensors read" | write_log

if [ -f $DATA_PATH/incoming_data.txt ];
then
 echo "New incoming data:";
 echo `cat $DATA_PATH/incoming_data.txt`
#cat $DATA_PATH/incoming_data.txt>$ARDUINO_PORT
 rm -f $DATA_PATH/incoming_data.txt
fi

ACTION_RECEIVED=""
if [ -f $DATA_PATH/incoming_action.txt ];
then
 ACTION_RECEIVED=`cat $DATA_PATH/incoming_action.txt`
 echo "New incoming action: $ACTION_RECEIVED"
 rm -f $DATA_PATH/incoming_action.txt
fi

# выполнить все скрипты
RFILES=$CFG_PATH/*.rule
for f in $RFILES
do
 if [ -f $f -a -x $f ]
  echo ${f##*/} | write_log
  . $f
 fi
done

if [ -f $DATA_PATH/reboot ];
then
echo "REBOOT FLAG"
echo "Reboot flag" | write_log
rm -f $DATA_PATH/reboot
break;
fi

# проверка изменения конфигурационых переменных
# Check files modified
echo "Check cfg vars" | write_log
FILES=$DATA_PATH/cfg*.dat
for f in $FILES
do
 if [ $f -nt $CFG_PATH/${f##*/} ]; then 
  echo "Copy $f ..."
  cp $f $CFG_PATH/
 fi
done
echo "6" | write_log
sleep 2 
done

done
#---------------------------------------------------------------------------

echo Cycle stopped.
echo "Cycle stopped." | write_log
