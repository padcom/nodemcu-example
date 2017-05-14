#!/bin/sh

docker run -it --rm --entrypoint bash ncarlier/mqtt -c "mosquitto_pub -h 192.168.32.2 -t bus/rf-link/cmd -m '30;RF=SEND;1;350;6;5575748;24;'"
