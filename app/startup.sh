#!/bin/bash
sleep 3

### config

# the max command length vclient can accept
MAX_LENGTH=512

# the usb device
USB_DEVICE=/dev/vitocal
echo "Device ${USB_DEVICE}"

### execution

# run vcontrold. This doesn't override the log file from the config on purpose. This way, if we change the file in the config, we can decide to keep the file.
vcontrold -x /config/vcontrold.xml -P /tmp/vcontrold.pid

# remove log file to avoid unlimited log growth.
rm "/log/deleteme.log"

status=$?
pid=$(pidof vcontrold)


# Function to execute vclient command with the current sublist
execute_vclient() {
    local current_list=$1
    local response

    # short format with -j. make sure to init merged_json as "{}".
    response=$(vclient -h 127.0.0.1:3002 -c "${current_list}" -j)
    merged_json=$(echo "$merged_json" | jq -c --argjson response "$response" '. * $response')

    # long format with -J. make sure to init merged_json as "[]".
    #response=$(vclient -h 127.0.0.1:3002 -c "${current_list}" -J)
    #merged_json=$(echo "$merged_json" | jq -c --argjson response "$response" '. + $response')
}


if [ $status -ne 0 ];then
	echo "Failed to start vcontrold"
fi

if [ $MQTTACTIVE = true ]; then
	echo "vcontrold started (PID $pid)"
	echo "MQTT: active (var = $MQTTACTIVE)"
	echo "Update interval: $INTERVAL sec"
        echo "Commands: $COMMANDS"

        /app/subscribe.sh

	while true; do

                # Temporary variable to build sublists
                sublist=""

                # merged results to the sublists
                merged_json="{}"

                # Split the COMMANDS string into sublists to avoid the 512 character limit on vclient. https://github.com/openv/vcontrold/pull/135
                IFS=','  # Set comma as the field separator
                for cmd in $COMMANDS; do

                    # Check if adding the next command exceeds the max length
                    if [[ ${#sublist} -eq 0 ]]; then
                        sublist="$cmd"
                    elif (( ${#sublist} + ${#cmd} + 1 <= MAX_LENGTH )); then
                        sublist+=",${cmd}"
                    else
                        # Execute the current sublist and reset
                        execute_vclient "$sublist"
                        sublist="$cmd"
                    fi

                done

                # Execute the last sublist if it exists
                if [[ -n $sublist ]]; then
                    execute_vclient "$sublist"
                fi


                # after all commands have been executed, publish the response.
                /app/publish.sh <<< "$merged_json"


		if [ -e /tmp/vcontrold.pid ]; then
			:
		else
			echo "vcontrold.pid doesn't exist. exit with code 0"
			exit 0
		fi

                sleep "$INTERVAL"
	done
else
	echo "vcontrold started (PID $pid)"
	echo "MQTT: inactive (var = $MQTTACTIVE)"
	echo "PID: $pid"

	while sleep 600; do
		if [ -e /tmp/vcontrold.pid ]; then
			:
		else
			echo "vcontrold.pid doesn't exist. exit with code 0"
			exit 0
		fi
	done
fi
