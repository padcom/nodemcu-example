dofile("credentials.lua")

local _wifi_timestamp = tmr.now()

print()
print("init.lua version 1.0")
print("MAC : " .. wifi.sta.getmac())
print("CHIP: " .. node.chipid())
print("HEAP: " .. node.heap())
uart.write(0, "Connecting to WiFi access point...")
wifi.setmode(wifi.STATION)
wifi.sta.config(SSID, PASSWORD)
wifi.sta.eventMonReg(wifi.STA_GOTIP, function()
  wifi.sta.eventMonStop()
  print("connected (" .. wifi.sta.getip() .. ", " .. (tmr.now() - _wifi_timestamp)/1000 .. "ms)")
  uart.write(0, "You have 3 seconds to abort...")
  tmr.create():alarm(3000, tmr.ALARM_SINGLE, function()
    if file.open("init.lua") == nil then
      print("init.lua deleted or renamed!")
    else
      print("starting application.")
      file.close("init.lua")
      -- the actual application is stored in 'application.lua'
      local status, err = pcall(function()
        dofile("application.lua")
      end)

      if not status then
        print("Error while running main application: " .. err)
      end
    end
  end)
end)
wifi.sta.eventMonStart()
