# openv-vcontrold-docker

Viessmann Optolink Control based on OpenV library.
This container uses the vcontrold deamon to connect to a Viessmann heating system.
To get get the values, the `vclient` tool is used. The responses are published mqtt broker.

The container supports an interval-based polling procedure of predefined (configured) command values as well as on-demand commands via MQTT.

In the compose file, we can configure the "COMMANDS" var to hold a comma-separated string of commands that will automatically be polled.
The "MQTTTOPIC" represents the base topic for all MQTT communication.
Based on this base topic, the container uses the following topics:  

- MQTTTOPIC/scheduled_poll: Responses of the automatic polling procedure get reported here.
- MQTTTOPIC/request: A comma-separated command string (i.e. "getTempWWObenIst,getTempWWsoll,setTempWWsoll 55") can be published here. the container will execute the commands and return the result.
- MQTTTOPIC/response: The results for the requests will be published here.


## Hardware requirements

To get this working you need an optolink adatper which is connected to the host system.
When starting this docker image you need to pass the device into the docker container.
As something like "/dev/ttyUSB0" can change / vary on reboot, I would recommend to use the serial id from the optolink adapter.
See example in below docker-compose.yaml file.
Please note that the device needs to be accessible for read/write operations from the user in the container. You probably have to adjust the rights using chmod.


## Software requirements

A MQTT broker is required in your environment where this container will send the values to.
If you just want to test the vclient to get values set MQTTACTIVE = false.
Then you can login to the container using `docker exec -it <containername> bash`.
In the shell you can then test your commands e.g. `vclient -h 127.0.0.1 -p 3002 -c getTempA,getTempB -j`.


## Configuration

The container expects to have the `vcontrold.xml` and `vito.xml` file passed to the `/config` folder.
Additionally, a `/log` folder can be mounted.
The log file will be configured in vcontrold.xml.
However, if you choose `/log/deleteme.log`, the log file will be deleted after creation to work around the lack of proper logrotate.


### MQTT

For the MQTT broker you need to define the following environment variables:
| variable      | desscription     | example value  |
| ------------- | ------------- | -----|
| MQTTACTIVE    | flag to set mqtt active | `true` or `false` |
| MQTTHOST      | hostname for mqtt broker | `192.168.1.2` or `broker.home` |
| MQTTPORT      | port for mqtt broker     |  `1883` |
| MQTTTOPIC     | prefix for topic followed by the command | `smarthome/optolink/` |
| MQTTUSER      | if mqtt broker requires authentification |  `mqtt_user` |
| MQTTPASSWORD  | if mqtt broker requires authentification |  `secret123` |


### Commands

The commands which should be read can be configured using the environment variable `COMMANDS`.
If you want to read multiple commands, each command must be separated by a comma.
As an example, my current `COMMANDS` variable looks like this:

```bash
COMMANDS=getTempWWObenIst,getTempWWsoll,getNeigungHK1,getTempVL,getTempRL,getPumpeStatusZirku,getBetriebArtHK1,getTempVListHK1,getTempRListHK1,getStatusVerdichter,getJAZ,getJAZHeiz,getJAZWW,getTempA,getPumpeStatusHK1
```


### Read interval

The environment variable `INTERVAL` defines the time in seconds


## Starting the container

The easiest way is to create a `docker-compose.yaml` file.
We can then use `docker compose up -d` (start) or `docker compose up -d --build vcontrold` (force rebuild).

Note: You probably need to give further rights to the device and the log folder.
Both need to be read/write for the user inside the container.

Here is an example file:

```yaml
version: '3.1'
services:
  vcontrold:
    #image: michelmu/vcontrold-openv
    build: .
	container_name: vcontrold
    restart: unless-stopped
    devices:
      - /dev/serial/by-id/usb-FTDI_FT232R_USB_UART_AL1234-if00-port0:/dev/ttyUSB0
    environment:
      MQTTACTIVE: true
      MQTTHOST: 10.6.91.24
      MQTTPORT: 1883
      MQTTTOPIC: vcontrold
      MQTTUSER: ""
      MQTTPASSWORD: ""
      INTERVAL: 30
      COMMANDS: "getTempWWObenIst,getTempWWsoll,getNeigungHK1"
    volumes:
      - ./config:/config
      - ./log//log

```

In order to pass the environment variables you can use the `.env` file and set the variables according to your needs.

If you want to use the `docker` command it would be e.g. `docker run -d --name='vcontrold' -e TZ="Europe/Berlin" -e 'MQTTACTIVE'='true' -e 'MQTTHOST'='mqtt-server.home' -e 'MQTTPORT'='1883' -e 'MQTTTOPIC'='vitocal' -e 'MQTTUSER'='mqtt_user' -e 'MQTTPASSWORD'='secret123' -e 'INTERVAL'='30' -e 'COMMANDS'='getTempWWObenIst,getTempWWsoll,getNeigungHK1' -v './config/':'/config':'rw' -v './log/':'/log':'rw' --device=/dev/serial/by-id/usb-FTDI_FT232R_USB_UART_AL1234-if00-port0:/dev/ttyUSB0:rw 'michelmu/vcontrold-openv-mqtt'`
