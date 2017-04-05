#!/bin/sh

nodemcu-tool remove application.lua rfrecv.lua restart.lua credentials.lua init.lua config
nodemcu-tool upload restart.lua credentials.lua init.lua application.lua rfrecv.lua
nodemcu-tool terminal --run restart.lua
