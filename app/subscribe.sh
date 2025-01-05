#!/bin/bash

# This script subscribes to a MQTT topic using mosquitto_sub.
# On each message received, you can execute whatever you want.

while true  # Keep an infinite loop to reconnect when connection lost/broker unavailable
do
    mosquitto_sub -u $MQTTUSER -P $MQTTPASSWORD -h $MQTTHOST -p $MQTTPORT -t $MQTTTOPIC/request -I "VCONTROLD-SUB" | while read -r payload

    do
        # Here is the callback to execute whenever you receive a message:
        #echo "Received MQTT message: ${payload}"
        response=$(vclient -h 127.0.0.1:3002 -c "${payload}" -j)
        mosquitto_pub -u $MQTTUSER -P $MQTTPASSWORD -h $MQTTHOST -p $MQTTPORT -t $MQTTTOPIC/response -m "$response" -x 120 -c --id "VCONTROLD-PUB" -V "mqttv5"
        #echo "Result: ${response}"
    done

    sleep 10  # Wait 10 seconds until reconnection

done & # Discomment the & to run in background (but you should rather run THIS script in background)
