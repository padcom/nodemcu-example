#!/bin/sh

nodemcu-tool upload init.lua config
nodemcu-tool terminal --run restart.lua
