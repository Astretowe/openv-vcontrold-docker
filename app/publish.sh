#!/bin/bash

PAYLOAD=$(cat)
mosquitto_pub -u $MQTTUSER -P $MQTTPASSWORD -h $MQTTHOST -p $MQTTPORT -t $MQTTTOPIC/scheduled_poll -m "$PAYLOAD" -x 120 -c --id "VCONTROLD-PUB" -V "mqttv5"
