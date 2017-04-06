#!/bin/sh

nodemcu-tool remove application.lua
nodemcu-tool remove rfrecv.lua
nodemcu-tool remove restart.lua
nodemcu-tool remove init.lua
nodemcu-tool remove config
nodemcu-tool upload restart.lua init.lua
nodemcu-tool terminal --run restart.lua
