#!/bin/sh

nodemcu-tool reset
nodemcu-tool upload restart.lua credentials.lua application.lua init.lua
#nodemcu-tool reset
nodemcu-tool terminal --run restart.lua

