#!/bin/sh

nodemcu-tool upload rfrecv.lua
nodemcu-tool terminal --run restart.lua
