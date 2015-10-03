#!/bin/bash

# settings
. /etc/master/settings.sh

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

TEST_FILE=$DATA_PATH/data_sent.txt
touch $TEST_FILE

SOCKET_HOST=connect.smartliving.ru
SOCKET_PORT=11444

exec 3<>/dev/tcp/$SOCKET_HOST/$SOCKET_PORT

NOW=$(date +"%H:%M:%S")
echo -n $NOW
echo " Sending: Hello!"
echo "Hello!">&3
read  -t 60 ok <&3
NOW=$(date +"%H:%M:%S")
echo -n $NOW
echo -n " Received: "
echo "$ok";

REGEX='^Please'
if [[ ! $ok =~ $REGEX ]]
then
 NOW=$(date +"%H:%M:%S")
 echo -n $NOW
 echo " Connection failed!"
 continue
fi

NOW=$(date +"%H:%M:%S")
echo -n $NOW
echo " Sending: auth:$MASTER_ID"
echo "auth:$MASTER_ID">&3
read -t 60 ok <&3
NOW=$(date +"%H:%M:%S")
echo -n $NOW
echo -n " Received: "
echo "$ok";

REGEX='^Authorized'
if [[ ! $ok =~ $REGEX ]]
then
 NOW=$(date +"%H:%M:%S")
 echo -n $NOW
 echo " Authorization failed!"
 exit 0
fi

NOW=$(date +"%H:%M:%S")
echo -n $NOW
echo " Sending: Hello again!"
echo "Hello again!">&3
read -t 60 ok <&3
NOW=$(date +"%H:%M:%S")
echo -n $NOW
echo -n " Received: "
echo "$ok";

while read -t 120 LINE; do

NOW=$(date +"%H:%M:%S")
echo -n $NOW
echo -n " Got line: "
echo $LINE

# Ping reply
REGEX='^PING'
if [[ $LINE =~ $REGEX ]]
then
echo -n $NOW
echo " Sending: PONG!"
echo PONG!>&3
fi

# Run action
REGEX='^ACTION:(.+)$'
if [[ $LINE =~ $REGEX ]]
then
DATA_RECEIVED=${BASH_REMATCH[1]}
NOW=$(date +"%H:%M:%S")
echo -n $NOW
echo -n " Action received: "
echo $DATA_RECEIVED
echo -n $DATA_RECEIVED>>$DATA_PATH/incoming_action.txt
fi


# Pass data
REGEX='^DATA:(.+)$'
if [[ $LINE =~ $REGEX ]]
then
DATA_RECEIVED=${BASH_REMATCH[1]}
echo -n $NOW
echo -n " Data received: "
echo $DATA_RECEIVED
echo -n $DATA_RECEIVED>>$DATA_PATH/incoming_data.txt
fi

# Pass data
REGEX='^URL:(.+)$'
if [[ $LINE =~ $REGEX ]]
then
DATA_RECEIVED=${BASH_REMATCH[1]}
echo -n $NOW
echo -n " URL received: "
echo 
wget -O $DATA_PATH/data_post.tmp http://localhost$DATA_RECEIVED
fi



# Check files modified
FILES=$DATA_PATH/*.dat
for f in $FILES
do
 if [ $f -nt $TEST_FILE ]; then 
  echo "Processing $f ..."
  FNAME=${f##*/}
  PARAM=${FNAME/.dat/}
  CONTENT=`cat $f`
  echo -n $NOW
  echo " Sending: DATA:$PARAM|$CONTENT;"
  echo "data:$PARAM|$CONTENT;">&3
 fi
done
touch $TEST_FILE


done <&3

done
#---------------------------------------------------------------------------

echo Cycle stopped.