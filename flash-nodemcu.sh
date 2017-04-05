#!/bin/sh

#esptool.py --port /dev/ttyUSB0 erase_flash

esptool.py --port /dev/ttyUSB0 write_flash -fm dio -fs 32m -ff 40m \
  0x000000 nodemcu-integer.bin \
  0x3fc000 esp_init_data_default.bin
