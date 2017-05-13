#!/bin/sh

docker run -it --rm --entrypoint bash ncarlier/mqtt -c "mosquitto_pub -h 192.168.32.2 -t bus/rf-link/out -m '10;Eurodomest;ID=0d5e43;SWITCH=05;CMD=ALLON;'"
