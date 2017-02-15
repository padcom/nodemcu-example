#!/bin/sh

nodemcu-tool upload application.lua
nodemcu-tool terminal --run restart.lua
