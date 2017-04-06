#!/bin/sh

nodemcu-tool remove application.lua
nodemcu-tool upload init.lua config
nodemcu-tool terminal --run restart.lua
