-- Initialize MQTT client
m = mqtt.Client()

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
  pcall(function()
    m:publish("system/logs", cjson.encode(entry), 0, 0)
  end)
end

-- Connect to MQTT server
m:connect("192.168.32.2", 1883, 0, 1, function(client)
  print("MQTT: connected");
  m:subscribe("bus/rf/433/out", 0);
end)

-- Process MQTT topic messages
m:on("message", function(c, topic, message)
  print("MQTT: topic=" .. topic .. "; message=" .. message)

  -- when a message is received on 'switch' queue send that code via RF transmitter
  if topic == "bus/rf/433/out" then
    -- the protocol: proto,pulse,repetitions,code,length
    -- eg. 1,350,4,5393,24
    local parser = string.gmatch(message, "[^,]+")
    local protocol = tonumber(parser())
    local pulse = tonumber(parser())
    local repetitions = tonumber(parser())
    local code = tonumber(parser())
    local length = tonumber(parser())
    log("Switch toggle", { protocol = protocol, pulse = pulse, repetitions = repetitions, code = code, length = length })
    rfswitch.send(protocol, pulse, repetitions, 6, code, length)
  end
end)

print("MQTT: setup completed")
