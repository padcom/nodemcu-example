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
    if not pcall(function()
      local parser = string.gmatch(message, "[^,]+")
      local protocol = tonumber(parser())
      local pulse = tonumber(parser())
      local repetitions = tonumber(parser())
      local code = tonumber(parser())
      local length = tonumber(parser())
      rfswitch.send(protocol, pulse, repetitions, 6, code, length)
      log("Switch toggle", { protocol = protocol, pulse = pulse, repetitions = repetitions, code = code, length = length })
    end) then
      log("Error while processing bus/rf/433/out message '" .. message .."'", {})
    end
  end
end)

print("MQTT: setup completed")

-- Initialize rfrecv
dofile('rfrecv.lua')

rfrecv.start(5, 2, 1, 8)
print("RFRECV: Setup completed")

