#!/bin/bash

# settings
. /etc/master/settings.sh


TIMENOW="$(date +%s)"
FILES=$DATA_PATH/*.timer
REGEX='-([0-9]+).timer$'
for f in $FILES
do
FNAME=${f##*/}
echo "$FNAME"
if [[ $FNAME =~ $REGEX ]]
then
 TIMEOUT=${BASH_REMATCH[1]}
 echo "$FNAME: timeout $TIMEOUT"
 diff = $(($TIMENOW - $TIMEOUT))
 if [ $diff -gt 0 ]; then
  #time passed
  TIMER_ACTION=`cat $DATA_PATH/$FNAME`
  echo "Action added: $TIMER_ACTION"
  #echo -n "$TIMER_ACTION">$DATA_PATH/incoming_action.txt
  echo "Deleting $FNAME"
  #rm -f $DATA_PATH/$FNAME
 fi
fi
done