#!/bin/bash

# settings
. /etc/master/settings.sh

api_key='V5YCOXLLZ66LBE3Z'
CFG_VAL=cfgThingspeak

if [ -f $DATA_PATH/$CFG_VAL.dat ]
then
  rtemp=$(cat $DATA_PATH/$CFG_VAL.dat)
  if [ $(cat $DATA_PATH/$CFG_VAL.dat) = "Yes" ]
  then
    sendstr="api_key=$api_key"
    # влажность в погребе
    if [ -f $DATA_PATH/Hcellar_S.dat ]
    then
      if [ $(cat $DATA_PATH/Hcellar_S.dat) = "OK" ]
      then
	sendstr="$sendstr&field1=$(cat $DATA_PATH/Hcellar.dat)"
      fi
    fi
    # температура в погребе
    if [ -f $DATA_PATH/Tcellar_S.dat ]
    then
      if [ $(cat $DATA_PATH/Tcellar_S.dat) = "OK" ]
      then
	sendstr="$sendstr&field2=$(cat $DATA_PATH/Tcellar.dat)"
      fi
    fi
    # температура в гараже
    if [ -f $DATA_PATH/Tgarage_S.dat ]
    then
      if [ $(cat $DATA_PATH/Tgarage_S.dat) = "OK" ]
      then
	sendstr="$sendstr&field3=$(cat $DATA_PATH/Tgarage.dat)"
      fi
    fi
    # статус вентилятора
    if [ -f $DATA_PATH/Fan_S.dat ]
    then
      if [ $(cat $DATA_PATH/Fan_S.dat) = "OK" ]
      then
	sendstr="$sendstr&field4=$(cat $DATA_PATH/Fan.dat)"
      fi
    fi
    # температура контроллера
    if [ -f $DATA_PATH/Tin_S.dat ]
    then
      if [ $(cat $DATA_PATH/Tin_S.dat) = "OK" ]
      then
	sendstr="$sendstr&field5=$(cat $DATA_PATH/Tin.dat)"
      fi
    fi
  fi
  
  # отправка на сервер
  #wget "http://api.thingspeak.com/update?$sendstr"
  wget "http://api.thingspeak.com/update?$sendstr" -O - > /dev/null
  #curl -k --data "$sendstr" https://api.thingspeak.com/update
fi
