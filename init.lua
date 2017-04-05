local _wifi_timestamp = tmr.now()

GPIO0  = 3
GPIO4  = 2
GPIO2  = 4
GPIO14 = 5
GPIO12 = 6
GPIO13 = 7
GPIO15 = 8
GPIO16 = 0


function isResetSwitchPressed()
  -- reset settings if GPIO16 low (default: high with pullup)
  gpio.mode(GPIO16, gpio.INPUT, gpio.PULLUP)
  return gpio.read(GPIO16) == 0
end

function resetWiFiConfig()
  wifi.sta.config({ ssid = "X", pwd = "12345678", auto = false, save = true })
end

function isWiFiConfigured()
  local config = wifi.sta.getdefaultconfig(true)
  return config.ssid ~= '' and config.ssid ~= 'X'
end

function startWiFiConfigWizard()
  uart.write(0, "Starting configuration wizzard...")
  local SSID = "EXAMPLE-" .. node.chipid()
  wifi.setmode(wifi.STATIONAP)
  wifi.ap.config({ ssid = SSID, auth = wifi.OPEN })
  enduser_setup.manual(true)
  enduser_setup.start(function()
    -- restart a second after the connection is made
    tmr.create():alarm(1000, tmr.ALARM_SINGLE, node.restart)
  end)
  print("access point: " .. SSID .. "...")
end

function getCurrentConfig()
  local config = { type = 'alamakota', version = 0 }
  if file.open('config', 'r') then
    pcall(function() config = cjson.decode(file.read()) end)
  end
  return config
end

function saveConfig(config)
  file.open('config', 'w')
  file.write(cjson.encode(config))
  file.flush()
  file.close()
end

function checkForUpdates(next)
  uart.write(0, "Checking for updates...")
  http.get("http://192.168.32.10:3000/alamakota", nil, function(code, data)
    if code < 0 or code ~= 200 then
      print("no update available ("..code..")")
    else
      local availableConfig = cjson.decode(data)
      local currentConfig   = getCurrentConfig()

      if currentConfig.version ~= availableConfig.version then
        print("new version available " .. availableConfig.version .. " (current: " .. currentConfig.version .. ") - updating system...")
        saveConfig(availableConfig)
        print("System updated - restarting...")
        node.restart()
      else
        print("current version (" .. currentConfig.version .. ") up to date")
        next()
      end
    end
  end)
end

function start()
  if file.open("init.lua") == nil then
    print("init.lua deleted or renamed!")
  else
    uart.write(0, "Starting application...")
    file.close("init.lua")

    -- the actual application is stored in 'application.lua'
    local status, err = pcall(function()
      dofile("application.lua")
      print("Done")
    end)

    if not status then
      print(err)
    end
  end
end

function onWiFiConnected()
  wifi.sta.eventMonStop()
  print("connected (" .. wifi.sta.getip() .. ", " .. (tmr.now() - _wifi_timestamp)/1000 .. "ms)")

  checkForUpdates(start)
end

-- Main

print()
print("init.lua version 1.1.1")
print("MAC : " .. wifi.sta.getmac())
print("CHIP: " .. node.chipid())
print("HEAP: " .. node.heap())

if isResetSwitchPressed() then
  resetWiFiConfig()
  node.restart()
elseif isWiFiConfigured() then
  uart.write(0, "Connecting to WiFi access point...")
  wifi.setmode(wifi.STATION)
  wifi.sta.eventMonReg(wifi.STA_GOTIP, onWiFiConnected)
  wifi.sta.eventMonStart()
  wifi.sta.connect()
else
  startWiFiConfigWizard()
end
