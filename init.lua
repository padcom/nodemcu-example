DEVICE_TYPE = 'alamakota'

local _wifi_timestamp = tmr.now()

GPIO0  = 3
GPIO4  = 2
GPIO2  = 4
GPIO14 = 5
GPIO12 = 6
GPIO13 = 7
GPIO15 = 8
GPIO16 = 0


local function isResetSwitchPressed()
  -- reset settings if GPIO16 low (default: high with pullup)
  gpio.mode(GPIO16, gpio.INPUT, gpio.PULLUP)
  return gpio.read(GPIO16) == 0
end

local function resetWiFiConfig()
  wifi.sta.config({ ssid = "X", pwd = "12345678", auto = false, save = true })
end

local function isWiFiConfigured()
  local config = wifi.sta.getdefaultconfig(true)
  return config.ssid ~= '' and config.ssid ~= 'X'
end

local function startWiFiConfigWizard()
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

local function getCurrentConfig()
  if file.open('config', 'r') then
    local ok, config = pcall(cjson.decode, file.read())
    if ok then return config  end
  end
  return { type = DEVICE_TYPE, version = 0, files = { } }
end

local function downloadFile(f, next)
  print("file: " .. f)
  http.get("http://192.168.32.10:3000/" .. DEVICE_TYPE .. "/" .. f, function(code, data)
    print(code, data)
    if code < 0 or code ~= 200 then
      print("no update available ("..code..")")
    else
      print("Saving file... ("..data..")")
      file.open(f, "w")
      file.write(data)
      file.flush()
      file.close()
    end
    print("File stored")
    next()
  end)
end

local function downloadFiles(index, files, next)
  print("index: "..index)
  if index == #files then
    print("a")
    downloadFile(files[index], next)
  else
    print("b")
    downloadFile(files[index], function() downloadFiles(index + 1, files, next) end)
  end
end

local function saveConfig(config)
  file.open('config', 'w')
  file.write(cjson.encode(config))
  file.flush()
  file.close()
end

local function checkForUpdates(next)
  uart.write(0, "Checking for updates...")
  http.get("http://192.168.32.10:3000/" .. DEVICE_TYPE, nil, function(code, data)
    if code < 0 or code ~= 200 then
      print("no update available ("..code..")")
    else
      local availableConfig = cjson.decode(data)
      local currentConfig   = getCurrentConfig()

      if currentConfig.version ~= availableConfig.version then
        print("new version (" .. availableConfig.version .. ") available (current: " .. currentConfig.version .. ") - updating")
        downloadFiles(1, availableConfig.files,
          function()
            print("Files downloaded - saving config...")
            saveConfig(availableConfig)

            print("System updated - restarting...")
            node.restart()
          end)
      else
        print("current version (" .. currentConfig.version .. ") up to date")
        next()
      end
    end
  end)
end

local function start()
  if file.open("init.lua") == nil then
    print("init.lua deleted or renamed!")
  else
    uart.write(0, "Starting application...")
    file.close("init.lua")

    -- the actual application is stored in 'application.lua'
    local status, err = pcall(dofile, "application.lua")

    if not status then
      print(err)
    end
  end
end

local function onWiFiConnected()
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
print()

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
