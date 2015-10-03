#!/bin/bash

ONLINE_CHECK_HOST="8.8.8.8"
# wait to be online
COUNTER=0
while [ $COUNTER -lt 30 ]; do
ping -c 1 $ONLINE_CHECK_HOST
if [[ $? = 0 ]];
then
echo Network available.
exit;
else
echo Network not available. Waiting...
sleep 30
fi
let COUNTER=COUNTER+1
done
LOGTIME=`date "+%Y-%m-%d %H:%M:%S"`
echo $LOGTIME": online reboot" >> /root/reboot 
echo Reboot...
reboot
