#!/bin/sh

nodemcu-tool remove init.lua
nodemcu-tool remove application.lua
nodemcu-tool remove config
nodemcu-tool upload init.lua
nodemcu-tool terminal --run restart.lua
