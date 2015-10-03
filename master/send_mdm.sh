#!/bin/bash

# отправка данных на сервер mojorDome подключенного по vpn lan2lan
#

# settings
. /etc/master/settings.sh

CFG_VAL=cfgMdm

if [ -f $DATA_PATH/$CFG_VAL.dat ]
then
  rtemp=$(cat $DATA_PATH/$CFG_VAL.dat)
  if [ $(cat $DATA_PATH/$CFG_VAL.dat) = "Yes" ]
  then
    sendstr="http://192.168.99.3/objects/?object=MyGorage&op=m&m=UpdateAll"
    # влажность в погребе
    if [ -f $DATA_PATH/Hcellar_S.dat ]
    then
      if [ $(cat $DATA_PATH/Hcellar_S.dat) = "OK" ]
      then
	sendstr="$sendstr&hp=$(cat $DATA_PATH/Hcellar.dat)"
      fi
    fi
    # температура в погребе
    if [ -f $DATA_PATH/Tcellar_S.dat ]
    then
      if [ $(cat $DATA_PATH/Tcellar_S.dat) = "OK" ]
      then
	sendstr="$sendstr&tp=$(cat $DATA_PATH/Tcellar.dat)"
      fi
    fi
    # температура в гараже
    if [ -f $DATA_PATH/Tgarage_S.dat ]
    then
      if [ $(cat $DATA_PATH/Tgarage_S.dat) = "OK" ]
      then
	sendstr="$sendstr&tg=$(cat $DATA_PATH/Tgarage.dat)"
      fi
    fi
    # статус вентилятора
    if [ -f $DATA_PATH/Fan_S.dat ]
    then
      if [ $(cat $DATA_PATH/Fan_S.dat) = "OK" ]
      then
	sendstr="$sendstr&fan=$(cat $DATA_PATH/Fan.dat)"
      fi
    fi
    # температура контроллера
    if [ -f $DATA_PATH/Tin_S.dat ]
    then
      if [ $(cat $DATA_PATH/Tin_S.dat) = "OK" ]
      then
	sendstr="$sendstr&td=$(cat $DATA_PATH/Tin.dat)"
      fi
    fi
  fi
  
  # отправка на сервер
  echo $sendstr
  curl $sendstr
fi
