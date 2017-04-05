#!/bin/sh

nodemcu-tool upload init.lua
nodemcu-tool terminal --run restart.lua
