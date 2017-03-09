#!/bin/bash

. /etc/master/settings.sh

ONLINE_CHECK_HOST="212.47.228.185"
VPN_CHECK_HOST="10.1.51.45"
VPN_CFG_VAL=cfgVpnChk
# wait to be online
COUNTER=0
while [ $COUNTER -lt 30 ]; do
ping -c 1 $ONLINE_CHECK_HOST
if [[ $? = 0 ]];
then
  echo Network available.
  # check VPN conection
  if [ -f $DATA_PATH/$VPN_CFG_VAL.dat ]
  then
    rtemp=$(cat $DATA_PATH/$VPN_CFG_VAL.dat)
    if [ $(cat $DATA_PATH/$VPN_CFG_VAL.dat) = "1" ]
    then
      COUNTER1=0
      while [ $COUNTER1 -lt 5 ]; do
        ping -c 1 $VPN_CHECK_HOST
        if [[ $? = 0 ]];
        then
          echo "VPN available."
          exit;
        else
          echo "VPN not available. Waiting..."
          sleep 15
        fi
        let COUNTER1=COUNTER1+1
      done
      # vpn connection not available - restart conection
      LOGTIME1=`date "+%Y-%m-%d %H:%M:%S"`
      echo $LOGTIME1": vpn restart" >> /root/reboot
      ifdown vpn
      sleep 10
      ifup vpn
      exit;
    fi
  fi  
  exit;
else
echo Network not available. Waiting...
sleep 30
fi
let COUNTER=COUNTER+1
done
LOGTIME=`date "+%Y-%m-%d %H:%M:%S"`
echo $LOGTIME": online reset usb power" >> /root/reboot
echo reset usb power...
echo 1 > /sys/class/gpio/gpio5/value
sleep 3
echo 0 > /sys/class/gpio/gpio5/value
exit;
