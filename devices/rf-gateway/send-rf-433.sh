#!/bin/sh

sudo docker run -it --rm --entrypoint bash ncarlier/mqtt -c "mosquitto_pub -h 192.168.32.2 -t bus/rf/433/out -m 1,260,4,8497336,24"
