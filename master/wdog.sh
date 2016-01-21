#!/bin/bash

# settings
. /etc/master/settings.sh
CFG_VAL=cfgWdog
LOGFILE=/var/log/masterlua.log

if [ -f $DATA_PATH/$CFG_VAL.dat ]
then
  rtemp=$(cat $DATA_PATH/$CFG_VAL.dat)
  if [ $(cat $DATA_PATH/$CFG_VAL.dat) = "1" ]
  then
    # проверка на наличии проверочного файла
    if [ -f $DATA_PATH/work_chk ]
    then
      # ошибка в работе скрипта - необходим перезапуск
      # сброс лога работы
      echo "File_exist"
      if [ -f $LOGFILE ]
      then
	echo "Save Log"
	SFILE="/root/chklog_"`date "+%Y_%m_%d_%H_%M_%S"`
	echo $SFILE
	tail $LOGFILE > $SFILE
	rm $LOGFILE
      fi
      # проверка наличия процесса
      LOGTIME=`date "+%Y-%m-%d %H:%M:%S"`
      if [ $(ps | grep 'master.lua' | grep -v 'grep' | wc -l) -eq 0 ]
      then
	# нет процесса - запустить
	echo "Restart"
	echo $LOGTIME": wdog restart" >> /root/reboot
	/etc/init.d/master start
	exit 0
      else
	# процесс есть - перезапустить систему
	echo "Reboot"
	echo $LOGTIME": wdog reboot" >> /root/reboot
	reboot
	exit 0
      fi
    else
     # корректная работа проверка правильная
     echo "" > $DATA_PATH/work_chk
     exit 0
    fi
  else
    # if desables remove chk file
    if [ -f $DATA_PATH/work_chk ]
    then
      echo "Cfg disabled - rm file"
      rm $DATA_PATH/work_chk
    fi
  fi
fi

