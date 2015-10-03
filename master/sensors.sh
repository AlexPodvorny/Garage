#!/bin/bash

# settings
#. /etc/master/settings.sh

ERROR_VALUE="-1"
W1_DIR="/1wire"

. /etc/master/fun_sensors.sh

# получить данные с 1-wire термометров
#echo "Read ..."
w1_read "Tin" "28.AF8179040000" "3"
w1_read "Tgarage" "28.389279040000" "3"
dht_read "Hcellar" "Tcellar" "/sys/class/my/dht" "2" 
gpioval_read "Fan" "0"
gpioval_read "bLed" "4"
gpioval_read "Button" "6"