#!/bin/sh

docker run -it --rm --entrypoint bash ncarlier/mqtt -c "mosquitto_sub -h 192.168.32.2 -t bus/rf-link/in -t bus/rf-link/out -t bus/rf-link/log -t bus/rf-link/cmd -t system/logs"
