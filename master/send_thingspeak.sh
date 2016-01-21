#!/bin/bash

# settings
. /etc/master/settings.sh


CFG_VAL=cfgThingspeak

if [ -f $DATA_PATH/$CFG_VAL.dat ]
then
  if [ $(cat $DATA_PATH/$CFG_VAL.dat) = "Yes" ]
  then
    sendstr="api_key=$api_key"

    # отправить сформированную строку
    if [ -f $DATA_PATH/strThingspeak.dat ]
    then
	sendstr="$sendstr$(cat $DATA_PATH/strThingspeak.dat)"
  	# отправка на сервер
  	wget "http://api.thingspeak.com/update?$sendstr" -O - > /dev/null
    fi
  fi
fi
