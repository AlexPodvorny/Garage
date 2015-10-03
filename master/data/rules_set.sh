# Rules set for device id: bb67-ebc1-6081-c922 from IP 176.60.176.153
# Updated 2015-05-13 09:41:33

# RULE 1 as (regex)


#Checking timers

TIMENOW="$(date +%s)"
FILES=$DATA_PATH/*.timer
REGEX='-([0-9]+).timer$'
for f in $FILES
do
FNAME=${f##*/}
if [[ $FNAME =~ $REGEX ]]
then
 TIMEOUT=${BASH_REMATCH[1]}
 DIFF=$(($TIMENOW-$TIMEOUT))
 if [ $DIFF -gt 0 ]; then
  #time passed
  TIMER_ACTION=`cat $DATA_PATH/$FNAME`
  echo "Action added: $TIMER_ACTION"
  echo -n "$TIMER_ACTION">$DATA_PATH/incoming_action.txt
  echo "Deleting $FNAME"
  rm -f $DATA_PATH/$FNAME
 fi
fi
done
