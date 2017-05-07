#!/bin/sh

docker run -it --rm --entrypoint bash ncarlier/mqtt -c "mosquitto_pub -h 192.168.32.2 -t bus/rf/433/out -m 1,350,4,5576017,24"
