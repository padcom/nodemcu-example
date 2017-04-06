dofile('rfsender.lua')

local sender = RfSender(GPIO14, GPIO12, GPIO15)
sender:send(1, 350, 4, 5393, 24)
