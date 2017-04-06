#!/bin/sh

nodemcu-tool remove rfsender.lua
nodemcu-tool upload rfsender.lua rfsender-test.lua
nodemcu-tool terminal --run rfsender-test.lua

