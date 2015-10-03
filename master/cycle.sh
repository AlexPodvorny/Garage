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
sleep 20

echo "System started" | write_log

# STEP 0
# wait to be online
COUNTER=0
while [ $COUNTER -lt 5 ]; do
ping -c 1 $ONLINE_CHECK_HOST
if [[ $? = 0 ]];
then
echo Network available.
break;
else
echo Network not available. Waiting...
sleep 5
fi
let COUNTER=COUNTER+1
done

#---------------------------------------------------------------------------
# START

if [ ! -d "$DATA_PATH" ]; then
  mkdir $DATA_PATH
  chmod 0666 $DATA_PATH
fi

while : 
do

#---------------------------------------------------------------------------

# Reading all data and sending to the web
#ALL_DATA_FILE=$DATA_PATH/all_data.txt
#rm -f $ALL_DATA_FILE
#echo -n id=$MASTER_ID>>$ALL_DATA_FILE
#echo -n "&data=">>$ALL_DATA_FILE
#FILES=$DATA_PATH/*.dat
#for f in $FILES
#do
##echo "Processing $f file..."
#OLD_DATA=`cat $f`
#fname=${f##*/}
#PARAM=${fname/.dat/}
#echo -n "$PARAM|$OLD_DATA;">>$ALL_DATA_FILE
#done
#ALL_DATA=`cat $ALL_DATA_FILE`
#echo Posting: $UPDATES_URL?$ALL_DATA
#wget -O $DATA_PATH/data_post.tmp $UPDATES_URL?$ALL_DATA

rm -f $DATA_PATH/*
# Востановить конфигурацинные файлы
cp $CFG_PATH/cfg*.dat $DATA_PATH/
# скпировать старые rules
if [ -f $CFG_PATH/rules_set.tmp ]
then 
 cp $CFG_PATH/rules_set.tmp $DATA_PATH//rules_set.sh
fi
echo "0" > $DATA_PATH/Hcycle.dat
echo "0" > $DATA_PATH/Hpause.dat
echo 0 > /sys/class/gpio/gpio0/value
echo 1 > /sys/class/gpio/gpio4/value

#---------------------------------------------------------------------------
# Downloading the latest rules from the web
echo "Downloading the latest rules from the web" | write_log
echo Getting rules from $UPDATES_URL?id=$MASTER_ID
wget -O $DATA_PATH/rules_set.tmp  $UPDATES_URL?id=$MASTER_ID
if grep -Fq "Rules set" $DATA_PATH/rules_set.tmp
then
cp $DATA_PATH/rules_set.tmp $CFG_PATH/ 
mv $DATA_PATH/rules_set.tmp $DATA_PATH/rules_set.sh
else
echo Incorrect rules file
fi



#---------------------------------------------------------------------------

# Downloading the latest menu from the web
echo "Downloading the latest menu from the web" | write_log
echo Getting menu from $UPDATES_URL/menu2.php?download=1\&id=$MASTER_ID
wget -O $DATA_PATH/menu.tmp  $UPDATES_URL/menu2.php?download=1\&id=$MASTER_ID
if grep -Fq "stylesheet" $DATA_PATH/menu.tmp
then
mv $DATA_PATH/menu.tmp $WEB_PATH/menu.html
else
echo Incorrect menu file
fi
#---------------------------------------------------------------------------

START_TIME="$(date +%s)"
# main cycle
#stty -F $ARDUINO_PORT ispeed $ARDUINO_PORT_SPEED ospeed $ARDUINO_PORT_SPEED cs8 ignbrk -brkint -imaxbel -opost -onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke noflsh -ixon -crtscts

#---------------------------------------------------------------------------
while [ 1=1 ] ; do

#echo $LINE
LINE="CYCLE"

echo "1" | write_log
echo "Cycle"


PASSED_TIME="$(($(date +%s)-START_TIME))"

## Processing incoming URLs from controller
#REGEX='^GET (.+)$'
#if [[ $LINE =~ $REGEX ]]
#then
#URL=$LOCAL_BASE_URL${BASH_REMATCH[1]}
##-URL=$LOCAL_BASE_URL
#wget -O $DATA_PATH/http.tmp $URL
#echo Getting URL
#echo $URL
#fi

PACKET_ID=""
DATA_FROM=""
DATA_TO=""
DATA_COMMAND=""
DATA_VALUE=""

REGEX='^P:([0-9]+);F:([0-9]+);T:([0-9]+);C:([0-9]+);D:([0-9]+);$'

# чтение датчиков
. /etc/master/sensors.sh
echo "2" | write_log

#if [[ $LINE =~ $REGEX ]]
#then
#PACKET_ID=${BASH_REMATCH[1]}
#DATA_FROM=${BASH_REMATCH[2]}
#DATA_TO=${BASH_REMATCH[3]}
#DATA_COMMAND=${BASH_REMATCH[4]}
#DATA_VALUE=${BASH_REMATCH[5]}
#DATA_FILE=$DATA_PATH/$DATA_FROM-$DATA_COMMAND.dat
#echo -n $DATA_VALUE>$DATA_FILE
#fi

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


echo "3" | write_log
. $DATA_PATH/rules_set.sh
echo "4" | write_log

if [ -f $DATA_PATH/reboot ];
then
echo "REBOOT FLAG"
echo "Reboot flag" | write_log
rm -f $DATA_PATH/reboot
break;
fi

# проверка изменения конфигурационых переменных
# Check files modified
echo "5" | write_log
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
done #< $ARDUINO_PORT

done
#---------------------------------------------------------------------------

echo Cycle stopped.