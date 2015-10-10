#!/bin/bash

#функция получения данных с 1-wire термометров
# вызов w1_read variable address max_error_count
function w1_read {
if [ -f "$W1_DIR/$2/temperature" ]
then
  wtemp=$(cat $W1_DIR/$2/temperature)
  if [ "$wtemp" ]
  then 
    echo $(printf %.1f $wtemp) > $DATA_PATH/$1.dat
    echo "OK" > $DATA_PATH/"$1"_S.dat
    if [ -f "$DATA_PATH/$1.cnt" ]
    then
      rm $DATA_PATH/$1.cnt
    fi
  else
    if [ -f "$DATA_PATH/$1.cnt" ]
    then
      COUNT=$(cat "$DATA_PATH/$1.cnt")
      if [ $COUNT -lt $3 ]
      then
	let COUNT=COUNT+1
	echo $COUNT > $DATA_PATH/$1.cnt
      else
	echo "ERROR" > $DATA_PATH/"$1"_S.dat
	echo $ERROR_VALUE > $DATA_PATH/$1.dat
      fi
    else
      echo "1" > $DATA_PATH/$1.cnt
    fi
  fi
else
if [ -f "$DATA_PATH/$1.cnt" ]
    then
      COUNT=$(cat "$DATA_PATH/$1.cnt")
      if [ $COUNT -lt $3 ]
      then
	let COUNT=COUNT+1
	echo $COUNT > $DATA_PATH/$1.cnt
      else
	echo "ERROR" > $DATA_PATH/"$1"_S.dat
	echo $ERROR_VALUE > $DATA_PATH/$1.dat
      fi
    else
      echo "1" > $DATA_PATH/$1.cnt
    fi
fi
}

# чтение днных с сенсора DHT22 (мой драйвер)
# переменные:
# - имя переменной влажности
# - имя переменной температуры
# - путь к файлу драйвера
# - число попыток чтения до установки ошибки
# - 5 - путь к файлу со значениями для усреднения
function dht_read {

if [ -f "$3" ]
then
  rtemp=$(cat $3)
  stemp=$(echo $rtemp | cut -f1 -d' ')
  if [ "$stemp" = "OK" ] 
  then
    hum=$(echo $rtemp | cut -f2 -d' ')
    tt=$(echo $rtemp | cut -f3 -d' ')
    # - усреднение 
    echo $hum >> $DATA_PATH/$5.avg
    SVAL=$(awk '{ s += $1 } END {printf "%0.1f %d", s/NR, NR}' $DATA_PATH/$5.avg)
    AVG=$(echo $SVAL | cut -f1 -d' ')
    NAVG=$(echo $SVAL | cut -f2 -d' ')
    while [ $NAVG -ge "10" ]; do
      sed -i '1d' $DATA_PATH/$5.avg
      let NAVG=NAVG-1
    done
    #
    echo $(printf %.1f $AVG) > $DATA_PATH/$1.dat
    echo $(printf %.0f $AVG) > $DATA_PATH/"$1"I.dat
    echo "OK" > $DATA_PATH/"$1"_S.dat
    if [ -f "$DATA_PATH/$1.cnt" ]
    then
      rm $DATA_PATH/$1.cnt
    fi
    echo $(printf %.1f $tt) > $DATA_PATH/$2.dat
    echo "OK" > $DATA_PATH/"$2"_S.dat
  else
    # ошибка чтения сенсора
    if [ -f "$DATA_PATH/$1.cnt" ]
    then
      COUNT=$(cat "$DATA_PATH/$1.cnt")
      if [ $COUNT -lt $4 ]
      then
	let COUNT=COUNT+1
	echo $COUNT > $DATA_PATH/$1.cnt
      else
	echo "ERROR" > $DATA_PATH/"$1"_S.dat
	echo $ERROR_VALUE > $DATA_PATH/$1.dat
	echo "ERROR" > $DATA_PATH/"$2"_S.dat
	echo $ERROR_VALUE > $DATA_PATH/$2.dat
	echo $ERROR_VALUE > $DATA_PATH/"$1"I.dat
      fi
    else
      echo "1" > $DATA_PATH/$1.cnt
    fi
  fi
else
# драйвер не загружен
  echo "ERROR" > $DATA_PATH/"$1"_S.dat
  echo $ERROR_VALUE > $DATA_PATH/$1.dat
  echo "ERROR" > $DATA_PATH/"$2"_S.dat
  echo $ERROR_VALUE > $DATA_PATH/$2.dat
  echo $ERROR_VALUE > $DATA_PATH/"$1"I.dat
fi
}

# функция чтения состояния порта gpio
# параметрый
# - имя переменной
# - номер gpio
function gpioval_read {

if [ -f "/sys/class/gpio/gpio$2/value" ]
then
  rtemp=$(cat "/sys/class/gpio/gpio$2/value")
  if [ "$rtemp" != "0" ] 
  then
    echo "1" > $DATA_PATH/$1.dat
  else
    echo "0" > $DATA_PATH/$1.dat
  fi
  echo "OK" > $DATA_PATH/"$1"_S.dat
else
# порт не настроен
  echo "ERROR" > $DATA_PATH/"$1"_S.dat
  echo $ERROR_VALUE > $DATA_PATH/$1.dat
fi
}
