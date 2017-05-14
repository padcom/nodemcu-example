uart.setup(0, 57600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1)

local function split(s, sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   s:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end

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
    if not pcall(function() processor(c, topic, message) end) then
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

PROCESSORS["bus/rf-link/out"] = function(client, topic, message)
  print(message)
  log("RF433 Sent", { message = message })
end

local COMMANDS = {}

PROCESSORS["bus/rf-link/cmd"] = function(client, topic, message)
  local command = split(message, ';')
  local subcmd  = split(command[2], '=')
  local params  = {}

  for i = 3, #command do
    params[i - 2] = split(command[i], '=')
  end

  local cmd = COMMANDS[subcmd[1]]
  if cmd ~= nil then
    if not pcall(function() cmd(subcmd[2], params) end) then
      log("Error while processing command " .. subcmd[1], {})
    end
  else
    log('Unknown command ' .. subcmd[1], {})
  end
end

COMMANDS['RESTART'] = function(subcmd, params)
  node.restart()
end

COMMANDS['LED'] = function(subcmd, params)
  if subcmd == "ON" then
    gpio.write(GPIO2, 0)
  elseif subcmd == "OFF" then
    gpio.write(GPIO2, 1)
  elseif subcmd == "BLINK" then
    local duration = tonumber(params[1][1])
    gpio.write(GPIO2, 0)
    tmr.alarm(4, duration, tmr.ALARM_SINGLE, function()
      gpio.write(GPIO2, 1)
    end)
  else
    log('Unknown LED subcommand ' .. subcmd, {})
  end
end

COMMANDS['RF'] = function(subcmd, params)
  if subcmd == 'SEND' then
    local protocol = tonumber(params[1][1])
    local pulse = tonumber(params[2][1])
    local repetitions = tonumber(params[3][1])
    local code = tonumber(params[4][1])
    local length = tonumber(params[5][1])
    rfsender:send(protocol, pulse, repetitions, code, length)
    log("RF=SEND", { protocol = protocol, pulse = pulse, repetitions = repetitions, code = code, length = length })
  else
    log('Unknown RF subcommand ' .. subcmd, {})
  end
end
