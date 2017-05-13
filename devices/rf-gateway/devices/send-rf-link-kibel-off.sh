#!/bin/sh

docker run -it --rm --entrypoint bash ncarlier/mqtt -c "mosquitto_pub -h 192.168.32.2 -t bus/rf-link/raw -m 1,360,4,5575764,24"
