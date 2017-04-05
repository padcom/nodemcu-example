-- dofile("credentials.lua")

GPIO0  = 3
GPIO4  = 2
GPIO2  = 4
GPIO14 = 5
GPIO12 = 6
GPIO13 = 7
GPIO15 = 8
GPIO16 = 0

local _wifi_timestamp = tmr.now()

print()
print("init.lua version 1.1")
print("MAC : " .. wifi.sta.getmac())
print("CHIP: " .. node.chipid())
print("HEAP: " .. node.heap())

-- reset settings if GPIO16 low (default: high with pullup)
gpio.mode(GPIO16, gpio.INPUT, gpio.PULLUP)
if gpio.read(GPIO16) == 0 then
  wifi.sta.config({ ssid = "X", pwd = "12345678", auto = false, save = true })
  node.restart()
end

-- start configuration wizzard if no previous settings exist
local wifi_config = wifi.sta.getdefaultconfig(true)
if wifi_config.ssid == '' or wifi_config.ssid == 'X' then
  print("Starting configuration wizzard...")

  local SSID = "EXAMPLE-" .. node.chipid()

  wifi.setmode(wifi.STATIONAP)
  wifi.ap.config({ ssid = SSID, auth = wifi.OPEN })
  enduser_setup.manual(true)
  enduser_setup.start(function() node.restart(); end)

  print("Started access point " .. SSID .. "...")
else
  wifi.setmode(wifi.STATION)

  function connected()
    wifi.sta.eventMonStop()
    print("connected (" .. wifi.sta.getip() .. ", " .. (tmr.now() - _wifi_timestamp)/1000 .. "ms)")

    uart.write(0, "Checking for updates...")
    http.get("http://192.168.32.10:3000/alamakota", nil, function(code, data)

      local function getCurrentVersion()
        if file.open('version', 'r') then
          local current_version = file.readline(version)
          file.close()
          return current_version:gsub("\n", "")
        else
          return "0"
        end
      end

      if code < 0 then
        print("HTTP request failed. Code: "..code)
      elseif not code == 200 then
        print("HTTP request failed. Code: "..code)
      else
        local config = cjson.decode(data)
        print("VERSION: " .. config.version)

        local should_update = 'false'
        local current_version = getCurrentVersion()
        print("CURRENT VERSION: "..current_version)

        if current_version ~= config.version then
          print("Updating system...")

          file.open('version', 'w')
          file.writeline(config.version)
          file.flush()
          file.close()

          print("System updated - restarting...")
          node.restart()
        end
      end
    end)

--    uart.write(0, "You have 3 seconds to abort...")
--    tmr.create():alarm(3000, tmr.ALARM_SINGLE, function()
--      if file.open("init.lua") == nil then
--        print("init.lua deleted or renamed!")
--      else
--        print("starting application.")
--          file.close("init.lua")
          -- the actual application is stored in 'application.lua'
--          local status, err = pcall(function()
--            dofile("application.lua")
--          end)

--          if not status then
--            print("Error while running main application: " .. err)
--          end
--        end
--      end)
--    end
  end

  uart.write(0, "Connecting to WiFi access point...")

  wifi.sta.eventMonReg(wifi.STA_GOTIP, connected)
  wifi.sta.eventMonStart()
  wifi.sta.connect()
end
