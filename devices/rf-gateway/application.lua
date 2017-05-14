uart.setup(0, 57600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1)

-- Clear prompt
print("\n\r")

GPIO5  = 1

-- Initialize MQTT client
m = mqtt.Client()

-- Publish message on MQTT topic
function publish(topic, message, qos, retain)
  pcall(function()
    m:publish(topic, message, qos, retain)
  end)
end

-- Send log message
function log(message, params)
  -- define base GEFL structure
  local entry = {
    version = '1.1',
    source = 'NodeMCU-' .. node.chipid(),
    facility = "433-rf-gateway",
    short_message = message
  }
  -- add any custom parameters
  for k, v in pairs(params) do
    entry['_' .. k] = v
  end
  -- send the log entry (inside a pcall to handle errors)
  publish("system/logs", cjson.encode(entry), 0, 0)
end

-- Connect to MQTT server
m:connect("192.168.32.2", 1883, 0, 1, function(client)
  publish("bus/rf-link/log", "30,MQTT,CONNECTED=1", 0, 0);
  m:subscribe("bus/rf-link/out", 0);
  m:subscribe("bus/rf-link/raw", 0);
  m:subscribe("bus/rf-link/cmd", 0);
  initHardware()
end)

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local PROCESSORS = {}

-- Process MQTT topic messages
m:on("message", function(c, topic, message)
  local processor = PROCESSORS[topic]
  if processor ~= nil then
    log("Processor found for topic " .. topic .. "found - processing", {})
    if not pcall(function()
      processor(c, topic, message)
    end) then
      log("Error while processing " .. topic .. " message '" .. message .."'", {})
    end
  else
    log("No processor found for topic '" .. topic .. "'", {})
  end
end)

function initHardware()
  -- Initialize rfsender
  dofile('rfsender.lua')
  publish("bus/rf-link/log", "30,RFSEND,STATUS=loaded", 0, 0)
  rfsender = RfSender(GPIO4, GPIO5, GPIO15)
  publish("bus/rf-link/log", "30,RFSEND,STATUS=ready", 0, 0)

  -- Initialize rfrecv
  dofile('rfrecv.lua')
  publish("bus/rf-link/log", "30,RFRECV,STATUS=loaded", 0, 0)

  rfrecv.init(GPIO12, GPIO2, function(code, bits, preamble, short, long)
    log("RF433 Received", { code = code, bits = bits })
    publish("bus/rf-link/in", "20,xx,ESP12E,ID=" .. code .. ",BITS=" .. bits, 0, 0)
  end)

  publish("bus/rf-link/log", "30,RFRECV,STATUS=ready", 0, 0)

  uart.on("data", "\n", function(data)
    log("RF433 Received", { data = data })
    uart.write(0, data)
    m:publish("bus/rf-link/in", data:gsub("%s+", ""), 0, 0)
  end, 0)

  publish("bus/rf-link/log", "30,RFLINK,STATUS=ready", 0, 0)
end

PROCESSORS["bus/rf-link/raw"] = function(client, topic, message)
  -- the protocol: proto,pulse,repetitions,code,length
  -- eg. 1,350,4,5393,24
  local parser = string.gmatch(message, "[^,]+")
  local protocol = tonumber(parser())
  local pulse = tonumber(parser())
  local repetitions = tonumber(parser())
  local code = tonumber(parser())
  local length = tonumber(parser())
  rfsender:send(protocol, pulse, repetitions, code, length)
  log("RF433 Sent", { protocol = protocol, pulse = pulse, repetitions = repetitions, code = code, length = length })
end

PROCESSORS["bus/rf-link/out"] = function(client, topic, message)
  print(message)
  log("RF433 Sent", { message = message })
end

PROCESSORS["bus/rf-link/cmd"] = function(client, topic, message)
  if message == "30;RESTART;" then
    node.restart()
  elseif message == "30;LED=ON;" then
    gpio.write(GPIO2, 0)
  elseif message == "30;LED=OFF;" then
    gpio.write(GPIO2, 1)
  elseif message == "30;LED=BLINK;" then
    gpio.write(GPIO2, 0)
    tmr.alarm(4, 1000, tmr.ALARM_AUTO, function()
      gpio.write(GPIO2, 1)
    end)
  end
end

