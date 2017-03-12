#!/bin/sh

nodemcu-tool remove application.lua receiver.lua
nodemcu-tool reset
nodemcu-tool upload restart.lua credentials.lua init.lua
nodemcu-tool terminal --run restart.lua
